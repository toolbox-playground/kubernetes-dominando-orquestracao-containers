```bash
k6 run test.js
```

## Checkando o HPA

```bash
while ($true) {
    kubectl get hpa | Where-Object { $_ -notmatch "kube-system" }
    Start-Sleep -Seconds 5
}
```

## Checkando quantidade de pods

```bash
while ($true) {
     kubectl top pods | Where-Object { $_ -notmatch "kube-system" }
     Start-Sleep -Seconds 5
}
```
