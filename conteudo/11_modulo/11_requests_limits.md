```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
  - name: myapp-container
    image: nginx:alpine
    resources:
      requests:
        memory: "128Mi"  # Quantidade mínima de memória que o Pod precisa
        cpu: "250m"      # Quantidade mínima de CPU
      limits:
        memory: "256Mi"  # Quantidade máxima de memória que o Pod pode usar
        cpu: "500m"      # Quantidade máxima de CPU que o Pod pode usar
```

## Explicações

• requests: Define o valor de recursos que o Kubernetes garante ao Pod.
• limits: Impõe um teto para o consumo de recursos, evitando que o Pod consuma demais e afete outros Pods.

## Boas Práticas para Requests e Limits

 • Defina valores apropriados para requests e limits: Sempre que possível, use valores realistas de requests para garantir que seus Pods sejam agendados corretamente, e defina limits para evitar que um Pod consuma todos os recursos.
 • Ajuste conforme o uso real: Analise o consumo real de recursos usando kubectl top e ajuste os valores de requests e limits conforme necessário.
 • Evite valores excessivamente altos para limits: Não configure limits muito altos para evitar desperdício de recursos e contenção para outros Pods.
