#!/bin/bash

set -e

function install_kubernetes() {
  echo "=============================="
  echo "Kubernetes Node Setup Script"
  echo "=============================="
  echo ""

  read -p "Enter the Kubernetes version you want to install (e.g. 1.31 or 1.32): " K8S_VERSION
  read -p "Is this a master node? (y/n): " IS_MASTER
  read -p "Enter a hostname for this node: " NODE_NAME

  echo "[+] Setting hostname to '$NODE_NAME'..."
  sudo hostnamectl set-hostname "$NODE_NAME"

  echo "[+] Disabling swap..."
  sudo swapoff -a
  sudo sed -i '/swap/d' /etc/fstab

  echo "[+] Updating and upgrading system..."
  sudo apt update && sudo apt upgrade -y

  echo "[+] Installing prerequisites..."
  sudo apt install -y apt-transport-https ca-certificates curl gpg gnupg lsb-release

  echo "[+] Enabling kernel modules for Kubernetes networking..."
  cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

  sudo modprobe overlay
  sudo modprobe br_netfilter

  echo "[+] Applying sysctl settings for Kubernetes networking..."
  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

  sudo sysctl --system

  echo "[+] Installing containerd..."
  sudo apt install -y containerd

  echo "[+] Configuring containerd..."
  sudo mkdir -p /etc/containerd
  containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
  sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

  sudo systemctl restart containerd
  sudo systemctl enable containerd

  echo "[+] Cleaning up any legacy Kubernetes repositories..."
  sudo rm -f /etc/apt/sources.list.d/kubernetes.list
  sudo rm -f /etc/apt/sources.list.d/archive_uri-http_apt_kubernetes_io-*.list
  sudo rm -f /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg
  sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  echo "[+] Setting up Kubernetes APT repository for version $K8S_VERSION..."
  sudo mkdir -p -m 755 /etc/apt/keyrings

  curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key" \
    | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" \
    | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

  sudo apt update

  echo "[+] Installing kubeadm, kubelet, kubectl version $K8S_VERSION..."
  sudo apt install -y --allow-downgrades --allow-change-held-packages kubelet="${K8S_VERSION}*" kubeadm="${K8S_VERSION}*" kubectl="${K8S_VERSION}*"

  sudo apt-mark hold kubelet kubeadm kubectl
  sudo systemctl enable --now kubelet

  K8S_VERSION_FULL="v${K8S_VERSION}"
  if [[ "$K8S_VERSION" =~ ^[0-9]+\.[0-9]+$ ]]; then
    K8S_VERSION_FULL="v${K8S_VERSION}.0"
  fi

  if [[ "$IS_MASTER" == "y" || "$IS_MASTER" == "Y" ]]; then
    echo "[+] Initializing Kubernetes master with kubeadm..."
    sudo kubeadm init --kubernetes-version "$K8S_VERSION_FULL"

    echo "[+] Setting up kubeconfig for current user..."
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    echo "[+] Installing Flannel network plugin..."
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

    echo "[+] Checking if podCIDR is set on the master node..."
    MASTER_NODE_NAME=$(hostname)
    POD_CIDR=$(kubectl get node "$MASTER_NODE_NAME" -o jsonpath="{.spec.podCIDR}")

    if [[ -z "$POD_CIDR" ]]; then
      echo "[!] podCIDR is empty. Patching node with 10.244.0.0/24..."
      kubectl patch node "$MASTER_NODE_NAME" -p '{"spec":{"podCIDR":"10.244.0.0/24"}}'

      echo "[+] Deleting Flannel pod to restart with updated podCIDR..."
      kubectl delete pod -n kube-flannel -l app=flannel

      echo "[✔] podCIDR patched successfully."
    else
      echo "[✔] podCIDR already set to: $POD_CIDR"
    fi
  else
    echo "[!] This is a worker node. After the master is ready, join the cluster using the kubeadm join command."
  fi

  echo ""
  echo "[✔] Kubernetes $K8S_VERSION installation completed successfully!"
}

function uninstall_kubernetes() {
  echo "[!] Resetting Kubernetes setup..."
  sudo kubeadm reset -f
  sudo rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd /var/lib/cni /etc/cni
  echo "[✔] Kubernetes uninstalled."
}

function deploy_deployment() {
  echo "[+] Deploying nginx Deployment..."
  cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy-configmap
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        configMap:
          name: nginx-html
EOF

  kubectl create configmap nginx-html --from-literal=index.html="<h1>Oi NGINX e ConfigMap!</h1>"
  echo "[✔] Deployment created."
}

function expose_nginx_nodeport() {
  kubectl expose deployment nginx-deploy-configmap --type=NodePort --port=80 || true
  kubectl get svc nginx-deploy-configmap
  NODE_PORT=$(kubectl get svc nginx-deploy-configmap -o jsonpath='{.spec.ports[0].nodePort}')
  NODE_IP=$(hostname -I | awk '{print $1}')
  echo "[✔] Service exposed on NodePort."
  echo "Use the following command to test: curl http://$NODE_IP:$NODE_PORT"
}

function port_forward() {
  echo "[+] Forwarding port 8080 to nginx Service..."
  kubectl port-forward svc/nginx-clusterip 8080:80
}

function troubleshooting() {
  echo "[+] Gathering cluster troubleshooting info..."

  echo "[+] Verifing nodes"
  kubectl get nodes -o wide

  echo "[+] Describing nodes"
  kubectl describe nodes

  echo "[+] Verifing all PODs"
  kubectl get pods -A
  
  echo "[+] Getting last 30 events"
  kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 30

  echo "[+] Checking podCIDR IPs..."
  kubectl get node $(hostname) -o jsonpath="{.spec.podCIDR}"


  echo "[✔] Troubleshooting complete."
}

function allow_pods_on_control_plane() {
  echo "[+] Removing taint from control-plane to allow pod scheduling..."
  kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true
  echo "[✔] Taint removed. Pods can now be scheduled on the control-plane."
}

function validate_nginx_service() {
  echo "[+] Validating Nginx Service..."
  NODE_PORT=$(kubectl get svc nginx-deploy -o jsonpath='{.spec.ports[0].nodePort}')
  NODE_IP=$(hostname -I | awk '{print $1}')
  echo "Trying: curl http://$NODE_IP:$NODE_PORT"
  curl http://$NODE_IP:$NODE_PORT || echo "[!] Failed to reach Nginx."
}

function upgrade_k8s_cluster() {
  echo "=============================="
  echo "Atualização do Cluster Kubernetes"
  echo "=============================="

  read -p "Digite a nova versão do Kubernetes (ex: 1.32): " NEW_VERSION

  echo "[+] Limpando repositórios antigos..."
  sudo rm -f /etc/apt/sources.list.d/kubernetes.list
  sudo rm -f /etc/apt/sources.list.d/archive_uri-http_apt_kubernetes_io-*.list
  sudo rm -f /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg
  sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  echo "[+] Configurando repositório APT para o Kubernetes v$NEW_VERSION..."
  sudo mkdir -p -m 755 /etc/apt/keyrings

  curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${NEW_VERSION}/deb/Release.key" \
    | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${NEW_VERSION}/deb/ /" \
    | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

  sudo apt-get update

  echo "[+] Atualizando kubeadm para a versão $NEW_VERSION..."
  sudo apt-mark unhold kubeadm
  sudo apt-get install -y --allow-change-held-packages kubeadm="${NEW_VERSION}*"
  sudo apt-mark hold kubeadm

  echo "[+] Executando 'kubeadm upgrade plan' para verificar possibilidades de upgrade..."
  sudo kubeadm upgrade plan

  read -p "Digite a versão completa (ex: v1.32.0) para atualizar: " FULL_VERSION
  echo "[+] Executando upgrade com kubeadm..."
  sudo kubeadm upgrade apply "$FULL_VERSION" -y

  echo "[+] Atualizando kubelet e kubectl..."
  sudo apt-mark unhold kubelet kubectl
  sudo apt-get install -y --allow-change-held-packages kubelet="${NEW_VERSION}*" kubectl="${NEW_VERSION}*"
  sudo apt-mark hold kubelet kubectl

  echo "[+] Reiniciando serviços..."
  sudo systemctl daemon-reexec
  sudo systemctl restart kubelet

  echo "[✔] Cluster atualizado para $FULL_VERSION com sucesso!"
}

run_backup() {
  echo "[+] Fazendo backup dos manifests e configs do cluster..."
  BACKUP_DIR="$HOME/k8s-backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP_DIR"

  echo "[+] Exportando todos os objetos do cluster..."
  kubectl get all --all-namespaces -o yaml > "$BACKUP_DIR/all-resources.yaml"

  echo "[+] Salvando ConfigMap e Secrets..."
  kubectl get configmaps --all-namespaces -o yaml > "$BACKUP_DIR/configmaps.yaml"
  kubectl get secrets --all-namespaces -o yaml > "$BACKUP_DIR/secrets.yaml"

  echo "[+] Backup salvo em: $BACKUP_DIR"
}

run_restore() {
  read -p "Digite o caminho completo do diretório de backup: " RESTORE_DIR
  if [[ ! -d "$RESTORE_DIR" ]]; then
    echo "[!] Diretório de backup não encontrado: $RESTORE_DIR"
    return
  fi

  echo "[+] Restaurando recursos do backup..."
  kubectl apply -f "$RESTORE_DIR/all-resources.yaml"
  kubectl apply -f "$RESTORE_DIR/configmaps.yaml"
  kubectl apply -f "$RESTORE_DIR/secrets.yaml"
  echo "[✔] Restauração concluída com sucesso."
}

deploy_nginx_with_pv() {
  echo "[+] Criando PersistentVolume e PersistentVolumeClaim..."

  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nginx-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/nginx-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

  echo "[+] Criando Deployment com PV/PVC e initContainer para copiar index.html..."

  cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-pv-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-pv
  template:
    metadata:
      labels:
        app: nginx-pv
    spec:
      volumes:
        - name: nginx-storage
          persistentVolumeClaim:
            claimName: nginx-pvc
      initContainers:
        - name: init-index
          image: busybox
          command: ["/bin/sh", "-c"]
          args:
            - echo "<h1>NGINX com volume persistente!</h1>" > /data/index.html;
          volumeMounts:
            - name: nginx-storage
              mountPath: /data
      containers:
        - name: nginx
          image: nginx
          ports:
            - containerPort: 80
          volumeMounts:
            - name: nginx-storage
              mountPath: /usr/share/nginx/html
EOF

  echo "[+] Expondo o Deployment como NodePort..."
  kubectl expose deployment nginx-pv-deploy --type=NodePort --port=80

  echo "[+] Aguardando Service ficar disponível..."
  sleep 5

  NODE_PORT=$(kubectl get svc nginx-pv-deploy -o jsonpath="{.spec.ports[0].nodePort}")
  NODE_IP=$(kubectl get nodes -o jsonpath="{.items[0].status.addresses[?(@.type=='InternalIP')].address}")

  echo ""
  echo "[✔] Tudo pronto! Para testar o acesso, use o comando:"
  echo "curl http://$NODE_IP:$NODE_PORT"
}

generate_kubeadm_token() {
  echo "[✔] Gerando token para ser usado no worker:"
  kubeadm token create --print-join-command
}

function deploy_nginx_clusterip() {
  echo "[+] Criando ConfigMap com index.html customizado..."
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-clusterip
data:
  index.html: |
    <html>
      <head><title>ClusterIP Example</title></head>
      <body>
        <h1>Você está acessando via ClusterIP + Port-Forward!</h1>
        <p>Feito com Kubernetes 💙</p>
      </body>
    </html>
EOF

  echo "[+] Criando Deployment do NGINX..."
  cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-clusterip
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-clusterip
  template:
    metadata:
      labels:
        app: nginx-clusterip
    spec:
      containers:
      - name: nginx-clusterip
        image: nginx:stable
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-volume
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
      volumes:
      - name: html-volume
        configMap:
          name: nginx-clusterip
EOF

  echo "[+] Criando Service tipo ClusterIP..."
  kubectl expose deployment nginx-clusterip --type=ClusterIP --port=80

  echo "[+] Esperando o pod do nginx ficar pronto..."
  kubectl wait --for=condition=ready pod -l app=nginx --timeout=60s

  echo "[+] Iniciando port-forward na porta 8080 -> nginx:80 ..."
  echo "[✔] Agora execute o seguinte comando para testar:"
  echo ""
  echo "    curl http://localhost:8080"
  echo ""

  kubectl port-forward svc/nginx-clusterip 8080:80
}

function deploy_nginx_with_loadbalancer() {
  echo "=============================="
  echo "Deploy do NGINX com LoadBalancer"
  echo "=============================="

  echo "[+] Criando arquivo index.html personalizado..."
  cat <<EOF > custom-index.html
<html>
  <head><title>NGINX via LoadBalancer</title></head>
  <body>
    <h1>Você acessou esse NGINX via LoadBalancer!</h1>
  </body>
</html>
EOF

  echo "[+] Criando ConfigMap com o conteúdo do index.html..."
  kubectl create configmap nginx-index-html --from-file=index.html=custom-index.html --dry-run=client -o yaml | kubectl apply -f -

  echo "[+] Criando Deployment com volume baseado em ConfigMap..."
  cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-lb-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-lb
  template:
    metadata:
      labels:
        app: nginx-lb
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-volume
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
      volumes:
      - name: html-volume
        configMap:
          name: nginx-index-html
EOF

  echo "[+] Criando Service tipo LoadBalancer..."
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-lb-service
spec:
  selector:
    app: nginx-lb
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
EOF

  echo "[+] Aguardando IP externo ser provisionado..."
  sleep 5
  while true; do
    EXTERNAL_IP=$(kubectl get svc nginx-lb-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [[ -z "$EXTERNAL_IP" ]]; then
      EXTERNAL_IP=$(kubectl get svc nginx-lb-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    if [[ -n "$EXTERNAL_IP" ]]; then
      break
    fi
    echo "   - Ainda aguardando IP externo... tentando novamente em 5 segundos."
    sleep 5
  done

  echo ""
  echo "[✔] Deploy concluído com sucesso!"
  echo "[✔] Execute o comando abaixo para testar o acesso:"
  echo ""
  echo "    curl http://$EXTERNAL_IP"
  echo ""
}

function install_ingress_controller() {
  echo "=============================="
  echo "Instalando NGINX Ingress Controller"
  echo "=============================="

  echo "[+] Aplicando manifest do ingress-nginx..."
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/cloud/deploy.yaml

  echo "[+] Aguardando o ingress-nginx controller estar pronto..."
  kubectl wait --namespace ingress-nginx \
    --for=condition=Ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s

  echo "[✔] Ingress Controller instalado com sucesso!"
}

function deploy_nginx_with_ingress() {
  echo "=============================="
  echo "Deploy NGINX + Ingress"
  echo "=============================="

  echo "[+] Criando index.html personalizado..."
  cat <<EOF > custom-index.html
<html>
  <head><title>NGINX via Ingress</title></head>
  <body>
    <h1>Você acessou esse NGINX via Ingress Controller!</h1>
  </body>
</html>
EOF

  echo "[+] Criando ConfigMap com index.html..."
  kubectl create configmap nginx-index --from-file=index.html=custom-index.html --dry-run=client -o yaml | kubectl apply -f -

  echo "[+] Criando Deployment..."
  cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ingress-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-ingress
  template:
    metadata:
      labels:
        app: nginx-ingress
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
        ports:
        - containerPort: 80
      volumes:
      - name: html
        configMap:
          name: nginx-index
EOF

  echo "[+] Criando Service ClusterIP..."
  kubectl expose deployment nginx-ingress-demo --port=80 --name=nginx-ingress-svc

  echo "[+] Criando Ingress..."
  cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-demo-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-ingress-svc
            port:
              number: 80
EOF

  echo "[+] Buscando IP da máquina atual (externo)..."
  EXTERNAL_IP=$(curl -s http://checkip.amazonaws.com)
  echo ""
  echo "[✔] Tudo pronto!"
  echo "    Acesse em: http://$EXTERNAL_IP"
  echo "    Ou use:   curl http://$EXTERNAL_IP"
  echo ""
}

function install_ingress_controller() {
  echo "=============================="
  echo "Instalando NGINX Ingress Controller"
  echo "=============================="

  echo "[+] Aplicando manifest do ingress-nginx..."
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/cloud/deploy.yaml

  echo "[+] Aguardando o ingress-nginx controller estar pronto..."
  kubectl wait --namespace ingress-nginx \
    --for=condition=Ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s

  echo "[✔] Ingress Controller instalado com sucesso!"
}

function deploy_nginx_with_ingress() {
  echo "=============================="
  echo "Deploy NGINX + Ingress"
  echo "=============================="

  echo "[+] Criando index.html personalizado..."
  cat <<EOF > custom-index.html
<html>
  <head><title>NGINX via Ingress</title></head>
  <body>
    <h1>Você acessou esse NGINX via Ingress Controller!</h1>
  </body>
</html>
EOF

  echo "[+] Criando ConfigMap com index.html..."
  kubectl create configmap nginx-index --from-file=index.html=custom-index.html --dry-run=client -o yaml | kubectl apply -f -

  echo "[+] Criando Deployment..."
  cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ingress-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-ingress
  template:
    metadata:
      labels:
        app: nginx-ingress
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
        ports:
        - containerPort: 80
      volumes:
      - name: html
        configMap:
          name: nginx-index
EOF

  echo "[+] Criando Service ClusterIP..."
  kubectl expose deployment nginx-ingress-demo --port=80 --name=nginx-ingress-svc

  echo "[+] Criando Ingress..."
  cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-demo-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-ingress-svc
            port:
              number: 80
EOF

  echo "[+] Buscando IP da máquina atual (externo)..."
  EXTERNAL_IP=$(curl -s http://checkip.amazonaws.com)
  echo ""
  echo "[✔] Tudo pronto!"
  echo "    Acesse em: http://$EXTERNAL_IP"
  echo "    Ou use:   curl http://$EXTERNAL_IP"
  echo ""
}

# Menu
clear
while true; do
  echo ""
  echo "O que você quer fazer?"
  echo "1) Instalar o Kubernetes"
  echo "2) Atualizar cluster Kubernetes"
  echo "3) Desinstalar o Kubernetes"
  echo "4) Permitir que o control-plane aceite PODs"

  echo "5) Deployar NGINX sem service"
  echo "6) Deployar NodePort Service para o NGINX"
  echo "7) Deployar NGINX com ClusterIP service"
  echo "8) Criar Port-Forward para NGINX ClusterIP"
  echo "9) Deployar NGINX com Volume e service"
  echo "10) Deployar NGINX com LoadBalancer"

  #echo "10) Validar funcionamento do NGINX"

  echo "11) Instalar Ingress Controller"
  echo "12) Deployar NGINX com Ingress"
  
  echo "13) Fazer backup do cluster"
  echo "14) Fazer restore do cluster"

  echo "15) Gerar Kubeadm token"
  echo "16) Troubleshooting"

  echo "0) Sair"
  read -p "Escolha uma opção: " CHOICE

  case $CHOICE in
    1) install_kubernetes;;
    2) upgrade_k8s_cluster ;;
    3) uninstall_kubernetes;;
    4) allow_pods_on_control_plane ;;
    
    5) deploy_deployment;;
    6) expose_nginx_nodeport;;
    7) deploy_nginx_clusterip ;;
    8) port_forward;;
    9) deploy_nginx_with_pv ;;
    10) deploy_nginx_with_loadbalancer;;
    #xx) validate_nginx_service ;;

    11) install_ingress_controller ;;
    12) deploy_nginx_with_ingress ;;

    13) run_backup ;;
    14) run_restore ;;

    15) generate_kubeadm_token ;;
    16) troubleshooting ;;

    0) echo "Saindo..."; exit 0 ;;
    *) echo "Opção inválida!" ;;
  esac

done
