Aqui está o cenário para a criação e configuração de **Ingress** no Kubernetes, formatado em Markdown e seguindo o padrão de documentação solicitado:

---

# Exercício: Criando e Configurando Ingress no Kubernetes

Neste exercício, vamos aprender sobre **Ingress** no Kubernetes, uma maneira poderosa de gerenciar o tráfego externo para os serviços dentro de um cluster. Vamos abordar os conceitos básicos de Ingress, configurar regras de roteamento de tráfego, e implementar TLS para segurança.

## 1. Preparação do Ambiente

Antes de começar, certifique-se de que você tenha acesso a um cluster Kubernetes em funcionamento e que o **Ingress Controller** esteja instalado no seu cluster. Você pode seguir a [documentação oficial](https://kubernetes.github.io/ingress-nginx/) para instalar o Ingress Controller caso ele não esteja instalado.

### 1.1. Criar o Deployment do Aplicativo

Vamos criar um aplicativo simples para ser exposto através do Ingress.

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

Aplique o deployment no cluster:

```bash
kubectl apply -f deployment.yaml
```

### 1.2. Criar o Serviço para Exposição

Agora, crie o serviço para expor o aplicativo.

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
  type: ClusterIP
```

Aplique o serviço no cluster:

```bash
kubectl apply -f service.yaml
```

---

## 2. Introdução ao Ingress

O **Ingress** no Kubernetes é uma API para gerenciar o acesso externo aos serviços em um cluster, geralmente com balanceamento de carga, SSL/TLS e roteamento baseado em URLs. Para usá-lo, é necessário um **Ingress Controller**, que é o responsável por implementar as regras de roteamento de tráfego.

Existem vários controladores de Ingress disponíveis, como o **Nginx Ingress Controller**, o **Traefik**, entre outros. Neste exercício, utilizaremos o Nginx Ingress Controller, que é amplamente utilizado.

---

## 3. Instalando o Ingress Controller (Nginx)

Se o **Ingress Controller** ainda não estiver instalado no seu cluster, você pode instalá-lo com o seguinte comando usando o Helm:

```bash
helm install nginx-ingress ingress-nginx/ingress-nginx --namespace kube-system
```

Verifique se o controlador foi instalado corretamente:

```bash
kubectl get pods -n kube-system
```

---

## 4. Criando uma Regra de Ingress

Agora, vamos configurar uma regra de Ingress para rotear o tráfego para o nosso serviço.

### 4.1. Criar o Arquivo de Configuração do Ingress

Crie o arquivo `ingress.yaml` com o seguinte conteúdo:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app-ingress
spec:
  rules:
    - host: web-app.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-app-service
                port:
                  number: 80
```

Aplique o arquivo de Ingress no cluster:

```bash
kubectl apply -f ingress.yaml
```

### 4.2. Verificar a Configuração do Ingress

Após aplicar a configuração, verifique se o Ingress foi criado corretamente:

```bash
kubectl get ingress
```

Agora, você pode acessar o serviço no endereço `http://web-app.local` se tiver configurado o DNS local ou editado o arquivo `/etc/hosts` para mapear `web-app.local` para o IP do seu Ingress Controller.

---

## 5. Implementando TLS para Segurança

Agora, vamos configurar **TLS** para garantir que a comunicação seja segura usando HTTPS.

### 5.1. Criar um Certificado SSL

Primeiro, crie um **Secret** com o certificado SSL para o seu domínio.

```bash
kubectl create secret tls web-app-tls --cert=certificado.crt --key=certificado.key
```

Substitua `certificado.crt` e `certificado.key` pelos seus próprios arquivos de certificado e chave privada.

### 5.2. Atualizar a Configuração de Ingress para Usar TLS

Atualize o arquivo `ingress.yaml` para configurar o TLS:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app-ingress
spec:
  tls:
    - hosts:
        - web-app.local
      secretName: web-app-tls
  rules:
    - host: web-app.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-app-service
                port:
                  number: 80
```

Aplique a atualização do Ingress:

```bash
kubectl apply -f ingress.yaml
```

Agora, a comunicação com o seu serviço será feita de forma segura via HTTPS.

---

## 6. Testando o Ingress com TLS

Para testar a configuração, acesse o serviço usando HTTPS:

```bash
https://web-app.local
```

Se tudo estiver configurado corretamente, você verá o serviço sendo servido com segurança via HTTPS.

---

## 7. Conclusão

Neste exercício, aprendemos sobre o **Ingress** no Kubernetes, como configurar regras de roteamento para serviços internos, e como implementar **TLS** para segurança. As etapas abordaram:

1. **Criação do Deployment e Serviço**: Para expor um aplicativo simples.
2. **Configuração do Ingress**: Para rotear o tráfego para o serviço com base em um domínio.
3. **Implementação de TLS**: Para garantir que a comunicação entre o cliente e o serviço seja segura.

Ingress é uma ferramenta poderosa para gerenciar o tráfego de entrada em um cluster Kubernetes e, com a configuração de TLS, podemos proteger os dados em trânsito.
