apiVersion: v1
kind: Namespace
metadata:
  name: meu-namespace-seguro
  labels:
    pod-security.kubernetes.io/enforce: "restricted"
    pod-security.kubernetes.io/enforce-version: "latest"