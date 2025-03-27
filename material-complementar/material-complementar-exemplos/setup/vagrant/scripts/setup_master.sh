#!/bin/bash

set -e

sudo apt update && sudo apt clean
sudo rm -rf /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo rm -f /etc/apt/sources.list.d/kubernetes.list
sudo apt update

# Atualiza pacotes e instala dependências
sudo apt update && sudo apt install -y apt-transport-https curl ca-certificates gnupg

# Instala a chave GPG do Docker corretamente
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg

# Adiciona o repositório do Docker
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu focal stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Atualiza pacotes e instala Docker
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io

sudo systemctl restart containerd
sudo systemctl status containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd


# Cria diretório antes de configurar o daemon do Docker
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl enable --now docker

# Configurar sysctl para Kubernetes
sudo modprobe br_netfilter
echo 'br_netfilter' | sudo tee /etc/modules-load.d/br_netfilter.conf
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# Adiciona a chave GPG e repositório do Kubernetes
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | \
sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

sudo mkdir -p /etc/apt/keyrings

# Atualiza pacotes e instala Kubernetes
sudo apt update && sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
kubeadm version

# Ativa o módulo necessário para o Kubernetes
sudo modprobe br_netfilter
echo 'br_netfilter' | sudo tee /etc/modules-load.d/k8s.conf

# Ajusta as configurações do kernel para Kubernetes
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

# Inicializa o Kubernetes
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=$(hostname -I | awk '{print $2}')

# Configura kubectl para o usuário vagrant
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Deploy Flannel network plugin
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Gera o comando de join para os workers
sudo kubeadm token create --print-join-command > /vagrant/scripts/join_command.sh
