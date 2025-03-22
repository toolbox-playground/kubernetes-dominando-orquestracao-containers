# Retorno de parte de um log de uma pod com um container
kubectl logs <pod-name>
  
# Retorno de parte de um log de uma pod para todos os container
kubectl logs <pod-name> --all-containers=true
  
# Retorno de parte de um log de uma pod que contém a label app e trazendo todos os container
kubectl logs -l app=<nome-da-label> --all-containers=true
  
# Streaming do log do container de uma pod
kubectl logs -f -c <nome-container> <pod-name> 
  
# Streaming os logs de todos os containers das pods que usarem a label determinada
kubectl logs -f -l app=<nome-da-label> --all-containers=true
  
# Resgatar o log das ultimas 20 linhas da pod
kubectl logs --tail=20 <nome-pod>
  
# Resgatar o log da ultima hora da pod
kubectl logs --since=1h <nome-pod>
  
# Resgatar o log de um kublet com um certificado expirado
kubectl logs --insecure-skip-tls-verify-backend <nome-pod>
  
# Retorna log do primeiro container do job chamado hello 
kubectl logs job/hello
  
# Retorna o log de um container de um deployment
kubectl logs deployment/<nome-do-deployment> -c <nome-container>