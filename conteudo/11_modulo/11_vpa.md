```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: myapp-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  updatePolicy:
    updateMode: "Auto"
```

## Explicação

• O VPA pode ajustar automaticamente o consumo de recursos (memória e CPU) conforme as necessidades do Pod.
• updateMode: "Auto" permite que o VPA ajuste as configurações automaticamente sem intervenção manual.

## Boas Práticas para Autoscaling (HPA e VPA)

• Use o HPA para cargas dinâmicas: O HPA é ideal para garantir que sua aplicação possa escalar automaticamente em resposta a picos de tráfego.
• Configure o VPA para otimizar recursos: O VPA é útil para garantir que os Pods não consumam nem mais nem menos recursos do que o necessário, ajustando as configurações de requests e limits conforme o uso real.
• Combinando HPA e VPA: Usar o HPA e o VPA juntos pode ser eficaz para otimizar tanto a quantidade de réplicas quanto os recursos alocados para cada Pod.
