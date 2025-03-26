# k8s-exemplos-basicos - Deployment

Neste exemplo, iremos efetuar o deploy e aplicar a a escala de pods desse deployment.

Temos o arquivo `deployment.yml`, que contém as informações básicas e necessárias para efetuar o deploymente do nosso container de teste.

## Comandos que iremos utilizar

Para aplicar o deployment dentro do nosso cluster, devemos executar o comando:

```
kubectl apply -f deployment.yml
```
![k8s-apply](img/01.png)

e para _checkar_ o status do nosso deployment, podemos executar o comando

```
kubectl get pods
```
![k8s-pods](img/02.png)

para saber o log da pod, execute

```
kubectl logs --tail=20 <nome-da-pod>
```
![k8s-logs](img/03.png)

Agora iremos executar o comando para alterar a quantidade de réplicas que 
```
kubectl scale deployment/node-beginner --replicas=4
```

e execute o comando para visualizar a quantidade de pods criadas

```
kubectl get pods
```
![k8s-logs](img/04.png)
