# Implementação de uma Solução de Rede

O Calico é um dos CNIs mais usados, oferecendo segurança e políticas de rede avançadas.

## Instalar o Calico no Cluster

Baixe o manifesto de instalação do Calico:

```
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml -O
```

Aplique o manifesto no cluster:

```
kubectl apply -f calico.yaml
```

```
kubectl get pods -n kube-system | grep calico
```
