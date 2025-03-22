#!/bin/bash

# Delete the Hello World Deployment and Service
echo "Deleting Deployment and Service..."
kubectl delete deployment hello-world
kubectl delete service hello-world-service

# Delete the Test Pod
echo "Deleting Test Pod..."
kubectl delete pod test-client

# Delete the Ingress (if used)
echo "Deleting Ingress..."
kubectl delete ingress hello-world-ingress

# Delete the Ingress Controller (if installed)
echo "Deleting Ingress Controller..."
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Clean up the /etc/hosts entry (manual step)
echo "If you added hello.local to /etc/hosts, remove it manually!"

echo "Cleanup completed!"
