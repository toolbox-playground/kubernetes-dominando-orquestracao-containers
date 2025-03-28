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
  sudo apt install -y kubelet="${K8S_VERSION}*" kubeadm="${K8S_VERSION}*" kubectl="${K8S_VERSION}*"

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
  name: nginx-deploy
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

  kubectl create configmap nginx-html --from-literal=index.html="<h1>Oi xuxu!</h1>"
  echo "[✔] Deployment created."
}

function expose_nginx_nodeport() {
  kubectl expose deployment nginx-deploy --type=NodePort --port=80 || true
  kubectl get svc nginx-deploy
  NODE_PORT=$(kubectl get svc nginx-deploy -o jsonpath='{.spec.ports[0].nodePort}')
  NODE_IP=$(hostname -I | awk '{print $1}')
  echo "[✔] Service exposed on NodePort."
  echo "Use the following command to test: curl http://$NODE_IP:$NODE_PORT"
}

function port_forward() {
  echo "[+] Forwarding port 8080 to nginx Service..."
  kubectl port-forward svc/nginx-deploy 8080:80
}

function troubleshooting() {
  echo "[+] Gathering cluster troubleshooting info..."
  kubectl get nodes -o wide
  kubectl get pods -A
  kubectl describe nodes
  kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 20
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

  echo "[+] Atualizando kubeadm para a versão $NEW_VERSION..."
  sudo apt-mark unhold kubeadm
  sudo apt-get update
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

# Menu
clear
while true; do
  echo ""
  echo "O que você quer fazer?"
  echo "1) Instalar o Kubernetes"
  echo "2) Desinstalar o Kubernetes"
  echo "3) Deployar Deployment (NGINX)"
  echo "4) Deployar NodePort Service (NGINX)"
  echo "5) Port-Forward para NGINX"
  echo "6) Troubleshooting"
  echo "7) Permitir que o control-plane aceite PODs"
  echo "8) Validar funcionamento do NGINX"
  echo "9) Atualizar cluster Kubernetes"
  echo "10) Fazer backup do cluster"
  echo "11) Fazer restore do cluster"
  echo "0) Sair"
  read -p "Escolha uma opção: " CHOICE

  case $CHOICE in
    1) install_kubernetes;;
    2) uninstall_kubernetes;;
    3) deploy_deployment;;
    4) expose_nginx_nodeport;;
    5) port_forward;;
    6) troubleshooting;;
    7) allow_pods_on_control_plane ;;
    8) validate_nginx_service ;;
    9) upgrade_k8s_cluster ;;
    10) run_backup ;;
    11) run_restore ;;
    0) echo "Saindo..."; exit 0 ;;
    *) echo "Opção inválida!" ;;
  esac

done
