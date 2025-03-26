Aplicar deployments
`
kubectl apply -f nginx.deployment.yml
`

Buscar deployments
`
kubectl get deployments
ou
kubectl get deployments <nome-deployment>
`

Escalar réplicas
`
kubectl scale deployment/<nome-deployment> --replicas=<numero>
`

Editar deployments
`
kubectl edit deployment <nome-deployment>
`

Mudar imagem
`
kubeclt set image deployment.v1.apps/rolling-deployment nginx=nginx:<new-version>
`

### Escalar pods
`
kubectl scale deployment/node-beginner --replicas=4
`

### Deletando deployment
`
kubectl delete deployment <nome-deployment> -n <nome-do-namespace>`