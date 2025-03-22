# Exercício: Criando HPA e Realizando Testes com K6

Neste exercício, vamos aprender como criar um **Horizontal Pod Autoscaler (HPA)** no Kubernetes e realizar testes de carga usando o **K6** para validar o desempenho e a escalabilidade do sistema.

## 1. Preparação do Ambiente

Certifique-se de que você tenha acesso ao seu cluster Kubernetes e tenha o K6 instalado em sua máquina local.

### 1.1. Criar o Deployment do Aplicativo

Vamos criar um deployment simples de um aplicativo que será escalado com o HPA.

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

### 1.2. Criar o Serviço para Exposição

Agora, vamos criar um serviço para expor o aplicativo.

Crie o arquivo `service.yaml`:

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
kubectl apply -f service.yaml
```

## 2. Criando o Horizontal Pod Autoscaler (HPA)

Agora, vamos criar o HPA para o nosso deployment.

Crie o arquivo `hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

Aplique o HPA no cluster:

```bash
kubectl apply -f hpa.yaml
```

## 3. Validando a Escalabilidade com K6

Agora que o HPA está configurado, vamos realizar testes de carga para verificar se o HPA escala corretamente os pods com o aumento da carga.

### 3.1. Criar o Script de Teste com K6

Crie um arquivo chamado `load-test.js` com o seguinte conteúdo:

```javascript
import http from 'k6/http';
import { sleep } from 'k6';

export default function () {
  http.get('http://web-app-service');
  sleep(1);
}
```

Este script fará requisições HTTP simples ao serviço exposto pelo Kubernetes.

### 3.2. Rodar o Teste de Carga

Execute o teste de carga com o K6:

```bash
k6 run load-test.js
```

O K6 começará a fazer requisições para o serviço e simulará carga. À medida que a carga aumentar, o HPA deve escalar os pods automaticamente, se necessário.

### 3.3. Monitorando o HPA

Você pode monitorar o HPA com o seguinte comando:

```bash
kubectl get hpa
```

Isso mostrará a quantidade de pods em execução e as métricas de utilização de CPU.

## 4. Verificando o Funcionamento do Autoscaler

Para verificar se o autoscaler está funcionando corretamente, execute os seguintes comandos para observar as métricas de escala e o número de pods:

```bash
kubectl get deployment web-app
kubectl get hpa
```