docker build -t local/node-api:canary .
docker build -t local/node-api:release .

```
kind load docker-image node-api:1.0.1 --name meu-cluster
kind load docker-image node-api:1.0.0 --name meu-cluster
```