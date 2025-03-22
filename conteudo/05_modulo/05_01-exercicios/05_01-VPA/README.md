# Exercício: Criando VPA e Validando o Ajuste de Recursos

Neste exercício, vamos aprender como configurar um **Vertical Pod Autoscaler (VPA)** no Kubernetes. O VPA ajusta automaticamente os recursos (CPU e memória) de um pod de acordo com a necessidade de desempenho, garantindo uma utilização otimizada dos recursos.

## 1. Preparação do Ambiente

Certifique-se de que você tenha acesso ao seu cluster Kubernetes e tenha configurado o **VPA** corretamente. O VPA precisa ser instalado no cluster antes de ser usado. Você pode seguir a [documentação oficial do VPA](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) para instalar o VPA se ele ainda não estiver instalado.

### 1.1. Criar o Deployment do Aplicativo

Vamos criar um deployment simples de um aplicativo que será gerenciado pelo VPA.

Crie o arquivo `deployment-vpa.yaml` com o seguinte conteúdo:

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
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

Aplique o arquivo no cluster:

```bash
kubectl apply -f deployment-vpa.yaml
```

### 1.2. Criar o Serviço para Exposição

Agora, vamos criar um serviço para expor o aplicativo.

Crie o arquivo `service-vpa.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
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
kubectl apply -f service-vpa.yaml
```

## 2. Criando o Vertical Pod Autoscaler (VPA)

Agora, vamos configurar o VPA para o nosso deployment, que ajustará automaticamente os recursos de CPU e memória.

Crie o arquivo `vpa.yaml` com o seguinte conteúdo:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: web-app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  updatePolicy:
    updateMode: "Auto"
```

Aplique o VPA no cluster:

```bash
kubectl apply -f vpa.yaml
```

## 3. Monitorando o VPA

O VPA monitorará o uso de recursos do pod e fará ajustes conforme necessário. Para verificar as recomendações feitas pelo VPA, você pode executar o seguinte comando:

```bash
kubectl get vpa web-app-vpa
```

Isso mostrará as recomendações de ajustes de recursos (memória e CPU) para o pod.

## 4. Testando o Ajuste de Recursos

Para validar o ajuste de recursos, vamos gerar uma carga para o pod e observar o comportamento do VPA.

### 4.1. Gerar Carga com `stress`

Vamos gerar carga no pod utilizando a ferramenta `stress`. Primeiro, crie um arquivo chamado `stress-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: stress-pod
spec:
  containers:
  - name: stress
    image: polinux/stress
    command:
      - "stress"
      - "--cpu"
      - "1"
      - "--timeout"
      - "60s"
```

Aplique o arquivo no cluster:

```bash
kubectl apply -f stress-pod.yaml
```

Isso fará com que o pod gere carga de CPU por 60 segundos. O VPA observará o uso de recursos e ajustará os limites de CPU e memória do pod.

### 4.2. Verificar o Ajuste de Recursos

Após o stress-test, você pode verificar as alterações nos recursos do pod com o seguinte comando:

```bash
kubectl describe pod web-app-<pod-name>
```

Procure por informações sobre os recursos `requests` e `limits` que foram ajustados pelo VPA.

## 5. Verificando o Funcionamento do VPA

Para verificar se o VPA está ajustando corretamente os recursos, execute o seguinte comando para observar os recursos do pod:

```bash
kubectl get pod -o wide
kubectl describe pod <nome-do-pod>
```

Se o VPA estiver funcionando corretamente, você verá que o `requests` e o `limits` de recursos foram ajustados com base no uso real do pod.