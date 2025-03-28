# Instalação e Configuração do KIND no Windows e Linux para Laboratório de Kubernetes

## 1. Instalação do Docker

Antes de instalar o KIND, é necessário ter o Docker instalado.

### Linux:
Execute os seguintes comandos para instalar o Docker:
```bash
sudo apt update && sudo apt install -y docker.io
sudo systemctl enable --now docker
```

Verifique a instalação:
```bash
docker --version
```

### Windows:
Baixe e instale o Docker Desktop a partir do site oficial:
[https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

Habilite o suporte ao Kubernetes no Docker Desktop.

## 2. Instalação do KIND

### Linux:
Execute os comandos abaixo:
```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x kind
sudo mv kind /usr/local/bin/
```

Verifique a instalação:
```bash
kind --version
```

### Windows:
Baixe o KIND para Windows:
1. Acesse [https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64](https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64)
2. Renomeie o arquivo para `kind.exe`
3. Mova o arquivo para um diretório incluído na variável de ambiente `PATH`, como `C:\\Windows\\System32`

Verifique a instalação:
```powershell
kind.exe --version
```

## 3. Criação do Cluster KIND

### Linux e Windows (PowerShell ou Terminal):
Execute o seguinte comando para criar um cluster com 1 master e 2 workers:

```bash
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF
```
ou

```bash
kind create cluster --config kind-config.yaml --name meu-cluster
```

Aguarde a criação do cluster.

## 4. Verificação do Cluster

Para verificar se os nós foram iniciados corretamente:
```bash
kubectl get nodes
```

Se os nós estiverem com status `Ready`, o cluster está pronto para uso.

## 5. Deploy da Aplicação de Teste

Agora que o cluster está provisionado, podemos fazer o deploy de uma aplicação de teste.

### Criar um arquivo de deployment YAML:
```bash
cat <<EOF > app-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx:latest
        ports:
        - containerPort: 80
EOF
```

Caso tenha necessidade de importar uma imagem local:
```
kind load docker-image node-api:latest --name meu-cluster
kind load docker-image java-api:latest --name meu-cluster
kind load docker-image py-api:latest --name meu-cluster
```

### Aplicar o deployment no cluster:
```bash
kubectl apply -f deployment.yaml
kubectl apply -f metrics-server.yaml
```

Teste as métricas
```
kubectl top nodes
kubectl top pods
```

### Verificar os pods em execução:
```bash
kubectl get pods
```