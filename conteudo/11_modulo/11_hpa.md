```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      targetAverageUtilization: 80
```

## Explicação

 • minReplicas: Número mínimo de réplicas para garantir a disponibilidade mínima.
 • maxReplicas: Número máximo de réplicas para evitar sobrecarga de recursos.
 • targetAverageUtilization: A média de uso de CPU para determinar quando escalar.
