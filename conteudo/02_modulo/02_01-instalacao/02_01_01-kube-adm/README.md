# Instalação do Kubernetes com Kubeadm

Se quiser um ambiente mais próximo do real, pode usar o `kubeadm` para criar um cluster com VMs.

## 1. Provisionamento das VMs

Crie 3 VMs com Ubuntu 22.04:
- 1 nó master
- 2 nós workers

## 2. Instalação de Dependências (em todas as VMs)

Execute os seguintes comandos em **todas as VMs**:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https curl
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl cri-o
```

## 3. Configuração do CRI-O (em todas as VMs)

```bash
sudo sed -i 's/^#sandbox_image =.*/sandbox_image = "registry.k8s.io/pause:3.6"/' /etc/crio/crio.conf
sudo systemctl daemon-reload
sudo systemctl restart crio
sudo systemctl enable crio
```

## 4. Criando o Cluster no Nó Master

No nó master, execute:
```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

## 5. Configuração do Acesso ao Cluster

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## 6. Adicionando os Workers ao Cluster

No nó **master**, gere o comando de `join` para os workers:
```bash
kubeadm token create --print-join-command
```

Execute o comando gerado **em cada worker** para adicioná-los ao cluster.

## 7. Verificando se o Cluster Está Pronto

No nó master, execute:
```bash
kubectl get nodes
```

Se os nós estiverem com status `Ready`, o cluster está configurado corretamente.
