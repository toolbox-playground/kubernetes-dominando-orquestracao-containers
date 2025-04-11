# Configurando um Persistent Volume (PV) e Persistent Volume Claim (PVC) no Kubernetes

## Aplicando a Configuração

### Aplicar o Persistent Volume (PV)

```bash
kubectl apply -f persistent-volume.yaml
```

### Aplicar o Persistent Volume Claim (PVC)

```bash
kubectl apply -f persistent-volume-claim.yaml
```

### Implantar o Pod que usa o PVC

```bash
kubectl apply -f pod-using-pvc.yaml
```

### Verificar se o PV e PVC estão vinculados

```bash
kubectl get pv
kubectl get pvc
```

### Verificar se o Pod está rodando

```bash
kubectl get pods
```

## Explicação dos Componentes

- Persistent Volume (PV): Representa o armazenamento disponível no cluster. Ele é criado pelo administrador e pode ser usado pelos usuários do cluster.
- Persistent Volume Claim (PVC): É uma solicitação de armazenamento feita por um Pod. O Kubernetes vincula automaticamente um - PVC a um PV disponível que atenda aos requisitos da solicitação.
- Pod: Usa a PVC para montar um volume persistente, garantindo que os dados sejam mantidos mesmo que o Pod seja reiniciado ou substituído.
