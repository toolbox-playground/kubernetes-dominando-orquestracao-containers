# 🧠 Dicas para Depuração no Kubernetes
## 1. Verificar o Status dos Nós

Garanta que todos os nós estejam no estado Ready:
```bash
kubectl get nodes
```

Se algum nó estiver como NotReady, veja os detalhes:
```bash
kubectl describe node <nome-do-no>
```

## 2. Verificar o Status dos Pods

Liste todos os pods e seus respectivos status:
```bash
kubectl get pods -A
```

Se algum pod estiver travado em Pending ou CrashLoopBackOff, veja os logs:
```bash
kubectl logs <nome-do-pod> -n <namespace>
```

## 3. Verificar Eventos

Veja se há avisos ou falhas registrados:
```bash
kubectl get events --sort-by='.lastTimestamp'
```

## 4. Depurando um Pod em Execução

Se um pod estiver em execução mas com problemas, acesse seu terminal:
```bash
kubectl exec -it <nome-do-pod> -- /bin/sh
```

*(Use /bin/bash se estiver disponível.)*

## 5. Verificar Conectividade de Rede

Verifique se os pods conseguem se comunicar entre si:
```bash
kubectl run test --rm -it --image=busybox -- /bin/sh
```

Dentro do shell, teste com:
```bash
wget -qO- <nome-do-serviço>:<porta>
```

## 6. Reiniciar um Pod

Às vezes, reiniciar resolve:
```bash
kubectl delete pod <nome-do-pod>
```

Se estiver usando um Deployment, um novo pod será recriado automaticamente.

## 7. Verificar Logs

Para logs dos componentes do Kubernetes:
```bash
journalctl -u kubelet -f
```

Para nós workers:
```bash
sudo docker ps
sudo docker logs <id-do-container>
```

## 8. Inspecionar o Networking com Flannel

Veja se o Flannel está rodando corretamente:
```bash
kubectl get pods -n kube-system | grep flannel
```

Se houver problemas, veja os detalhes do pod:
```bash
kubectl describe pod <flannel-pod> -n kube-system
```

## 9. Verificar Acessibilidade de Serviços

Confirme se seu serviço está acessível:
```bash
kubectl get svc
```

Se estiver usando NodePort, acesse via:
```bash
curl http://<ip-do-no>:<porta-do-nodeport>
```

## 10. Resetar o cluster
```bash
kubeadm reset
rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd /var/lib/cni /etc/cni
systemctl restart containerd
```

## 11. Verificar configurações do Containerd
```bash
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```

## 12. Verificar CIDR no Flannel
```bash
kubectl get node master -o jsonpath="{.spec.podCIDR}"
kubectl patch node master -p '{"spec":{"podCIDR":"10.244.0.0/24"}}'
kubectl delete pod -n kube-flannel -l app=flannel
```

## 🧹 Substituindo o Flannel pelo Calico
```bash
kubectl get pods -n kube-system -l app=flannel
kubectl get daemonset -n kube-system
```

### Remover o Flannel
```bash
kubectl delete -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

### Limpar resíduos do Flannel
```bash
sudo rm -rf /var/lib/cni/
sudo rm -rf /run/flannel/
sudo rm -rf /etc/cni/net.d
sudo systemctl restart kubelet
```

### Instalar o Calico
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
kubectl get pods -n kube-system -l k8s-app=calico-node
```

### Testar conectividade
```bash
kubectl run test-pod1 --image=busybox -it --restart=Never -- sh
```

### Dentro do pod
```bash
ping test-pod2
```
