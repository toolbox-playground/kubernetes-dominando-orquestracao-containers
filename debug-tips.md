# Kubernetes Debugging Tips

### 1️⃣ Check Node Status
Ensure all nodes are in a `Ready` state:
```sh
kubectl get nodes
```
If a node is `NotReady`, check its details:
```sh
kubectl describe node <node-name>
```

### 2️⃣ Check Pod Status
List all pods and their statuses:
```sh
kubectl get pods -A
```
If a pod is stuck in `Pending` or `CrashLoopBackOff`, get logs:
```sh
kubectl logs <pod-name> -n <namespace>
```

### 3️⃣ Check Events
Check if there are warnings or failures:
```sh
kubectl get events --sort-by='.lastTimestamp'
```

### 4️⃣ Debugging a Running Pod
If a pod is running but misbehaving, access its shell:
```sh
kubectl exec -it <pod-name> -- /bin/sh
```
(Use `/bin/bash` if it's available.)

### 5️⃣ Check Network Connectivity
Verify that pods can reach each other:
```sh
kubectl run test --rm -it --image=busybox -- /bin/sh
```
Inside the shell, try:
```sh
wget -qO- <service-name>:<port>
```

### 6️⃣ Restarting a Pod
Sometimes, restarting helps:
```sh
kubectl delete pod <pod-name>
```
If using a **Deployment**, a new pod will be created automatically.

### 7️⃣ Checking Logs
For logs of Kubernetes components:
```sh
journalctl -u kubelet -f
```
For worker nodes:
```sh
sudo docker ps
sudo docker logs <container-id>
```

### 8️⃣ Inspect Flannel Networking
Check if Flannel is running correctly:
```sh
kubectl get pods -n kube-system | grep flannel
```
If there are issues, describe the pod:
```sh
kubectl describe pod <flannel-pod> -n kube-system
```

### 9️⃣ Verifying Service Accessibility
Ensure your service is reachable:
```sh
kubectl get svc
```
If using **NodePort**, access it via:
```sh
curl http://<node-ip>:<nodeport>
```

### 🔟 Last Resort: Restart Everything
```sh
vagrant destroy -f
vagrant up
```
If issues persist, double-check your configuration files and scripts!
