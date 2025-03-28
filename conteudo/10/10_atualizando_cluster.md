🪜 Etapas Manuais para Atualização (Control Plane)

1. 📦 Desbloquear e atualizar o kubeadm
```bash
sudo apt-mark unhold kubeadm
sudo apt update
sudo apt install -y kubeadm=1.32.* --allow-change-held-packages
```

Verifique a versão instalada:
```bash
kubeadm version
```

2. ⚙️ Planejar a atualização (verifica se é possível)
```bash
sudo kubeadm upgrade plan
```

Esse comando mostra:
- A versão atual do cluster
- A versão para a qual você pode atualizar
- Verifica compatibilidade

3. 🚀 Atualizar o Control Plane
```bash
sudo kubeadm upgrade apply v1.32.0
```

*(ou substitua v1.32.0 pela versão sugerida no plano)*

4. 🔄 Atualizar o kubelet e o kubectl
```bash
sudo apt install -y kubelet=1.32.* kubectl=1.32.* --allow-change-held-packages
sudo apt-mark hold kubelet kubectl
```

5. 🔁 Reiniciar o kubelet
```bash
sudo systemctl daemon-reexec
sudo systemctl restart kubelet
```

✅ Verificação
```bash
kubectl get nodes
kubectl version
```
