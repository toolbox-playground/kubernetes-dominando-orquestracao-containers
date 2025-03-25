apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: myapp
    image: nginx:alpine
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
          - ALL
      readOnlyRootFilesystem: true

Explicações:
	•	runAsNonRoot: true → Garante que o processo não será executado como root.
	•	allowPrivilegeEscalation: false → Bloqueia que o processo aumente privilégios.
	•	readOnlyRootFilesystem: true → Garante que o sistema de arquivos seja somente leitura.