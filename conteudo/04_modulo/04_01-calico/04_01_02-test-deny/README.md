# Verificação da Conectividade entre Pods

Após instalar o Calico, podemos testar a comunicação entre os Pods.

Aplicar no cluster:

```bash
kubectl apply -f deny-all.yaml
```

## Testar a comunicação

Acesse o primeiro pod:

```bash
kubectl exec -it pod-a -- /bin/sh
```

Pegue o IP do segundo pod:

```bash
kubectl get pod pod-b -o wide
```

Faça um teste de conectividade (ping):

```bash
ping <IP_do_pod-b>
```

Se houver resposta, a rede está funcionando corretamente!
