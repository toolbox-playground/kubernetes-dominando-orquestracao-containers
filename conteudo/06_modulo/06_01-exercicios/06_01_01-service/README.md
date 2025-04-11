# Exercício: Criando Serviços do Kubernetes

Neste exercício, vamos aprender como criar diferentes tipos de serviços no Kubernetes: **ClusterIP**, **NodePort** e **LoadBalancer**. Esses serviços ajudam a expor seus pods de maneiras diferentes, dependendo das suas necessidades.

## 1. Preparação do Ambiente

Certifique-se de que você tenha acesso ao seu cluster Kubernetes e tenha um **Deployment** em funcionamento que possa ser exposto pelos serviços.

### 1.1. Criar o Deployment do Aplicativo

Crie o arquivo `deployment.yaml` com o seguinte conteúdo:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: nginxdemos/hello
        ports:
        - containerPort: 80
```

Aplique o arquivo no cluster:

```bash
kubectl apply -f deployment.yaml
```

---

## 2. Criando um Serviço do Tipo ClusterIP

O **ClusterIP** é o tipo de serviço mais comum e expõe o serviço internamente dentro do cluster. Não é acessível externamente.

### 2.1. Criar o Serviço ClusterIP

Crie o arquivo `service-clusterip.yaml` com o seguinte conteúdo:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-clusterip
spec:
  selector:
    app: web-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

Aplique o serviço:

```bash
kubectl apply -f service-clusterip.yaml
```

### 2.2. Verificar o Serviço ClusterIP

Após aplicar o serviço, verifique se ele foi criado corretamente:

```bash
kubectl get svc web-app-clusterip
```

Isso mostrará o IP do cluster atribuído ao serviço, que só pode ser acessado dentro do cluster.

---

## 3. Criando um Serviço do Tipo NodePort

O **NodePort** expõe o serviço em cada nó do cluster através de um IP e uma porta específica. É acessível externamente através do IP do nó e da porta configurada.

### 3.1. Criar o Serviço NodePort

Crie o arquivo `service-nodeport.yaml` com o seguinte conteúdo:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-nodeport
spec:
  selector:
    app: web-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
  type: NodePort
```

Aplique o serviço:

```bash
kubectl apply -f service-nodeport.yaml
```

### 3.2. Verificar o Serviço NodePort

Após aplicar o serviço, verifique se ele foi criado corretamente:

```bash
kubectl get svc web-app-nodeport
```

Isso mostrará a porta `30080` para acessar o serviço externamente em qualquer nó do cluster.

---

## 4. Criando um Serviço do Tipo LoadBalancer

O **LoadBalancer** cria um balanceador de carga externo que distribui o tráfego para os pods do serviço. Esse tipo de serviço é utilizado para expor aplicativos de forma acessível externamente com balanceamento de carga.

### 4.1. Criar o Serviço LoadBalancer

Crie o arquivo `service-loadbalancer.yaml` com o seguinte conteúdo:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-loadbalancer
spec:
  selector:
    app: web-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
```

Aplique o serviço:

```bash
kubectl apply -f service-loadbalancer.yaml
```

### 4.2. Verificar o Serviço LoadBalancer

Após aplicar o serviço, verifique se ele foi criado corretamente e se um IP externo foi atribuído:

```bash
kubectl get svc web-app-loadbalancer
```

O Kubernetes criará um balanceador de carga externo e você verá o IP atribuído ao serviço. Esse IP pode ser usado para acessar o serviço externamente.

---

## 5. Conclusão

1. **ClusterIP**: Exposto apenas dentro do cluster.
2. **NodePort**: Exposto externamente por meio de um IP de nó e uma porta configurada.
3. **LoadBalancer**: Exposto externamente com um balanceador de carga atribuído automaticamente.
