# Instalação do Kubernetes com Manual

## 1. Provisionamento das VMs

Crie 3 VMs com Ubuntu 22.04:

- 1 nó master
- 2 nós workers

## 2. Requisitos básicos para todos os nós

### Desabilitar swap

```
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
```

### Setar hostname

```
sudo hostnamectl set-hostname <node-name>
```

### Entradas no /etc/hosts

```
echo "192.168.1.100 master" | sudo tee -a /etc/hosts
echo "192.168.1.101 worker1" | sudo tee -a /etc/hosts
echo "192.168.1.102 worker2" | sudo tee -a /etc/hosts
```

## 3. Instalação das Dependências (Executar em todos os nós)

### Atualizar o sistema

```
sudo apt update && sudo apt upgrade -y
```

### Pacotes básicos necessários

```
sudo apt install -y apt-transport-https ca-certificates curl gnupg
```

### Carregar módulos do Kernel

```
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
```

### 4. Setar sysctl parâmetros

```
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system

sudo sysctl net.ipv4.ip_forward=1

echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Instalação do Containerd (Executar em todos os nós)

### Instalar containerd

```
sudo apt install -y containerd
```

#### Configurar o containerd

```
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```

### Reiniciar containerd

```
sudo systemctl restart containerd
sudo systemctl enable containerd
```
