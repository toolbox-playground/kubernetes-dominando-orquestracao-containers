## Módulo: Segurança e Controle de Acesso no Kubernetes

### Introdução

Neste módulo, vamos abordar os principais mecanismos de segurança no Kubernetes relacionados ao controle de acesso e ao ambiente de execução dos containers. O foco será o RBAC (Role-Based Access Control), a criação e uso de usuários, e o uso do `securityContext` para configurar regras de execução seguras para os pods. Este conteúdo é essencial para qualquer profissional que deseja administrar clusters Kubernetes com responsabilidade e segurança.

### O que é RBAC?

RBAC (Role-Based Access Control) é um método de controle de acesso baseado em funções utilizado no Kubernetes para definir quem pode acessar o quê dentro do cluster. Em outras palavras, o RBAC permite administrar permissões de forma granular, garantindo segurança e organização nas operações do cluster.

### Componentes do RBAC

Existem quatro componentes principais no RBAC:

- **Roles e ClusterRoles**: Definem um conjunto de permissões sobre recursos específicos.
- **RoleBindings e ClusterRoleBindings**: Associam usuários ou grupos às Roles ou ClusterRoles criadas.

A principal diferença entre Role e ClusterRole é o escopo:

- **Role** é restrito a um namespace específico.
- **ClusterRole** é aplicado ao cluster inteiro.

### Como criar um usuário em Kubernetes

O Kubernetes não gerencia diretamente usuários; geralmente são utilizados certificados ou ferramentas externas. A maneira mais comum de criar um usuário é gerando certificados utilizando o OpenSSL ou ferramentas como o cfssl.

Exemplo de criação de usuário usando OpenSSL:

```bash
openssl genrsa -out dev.key 2048
openssl req -new -key dev.key -out dev.csr -subj "/CN=dev"
openssl x509 -req -in dev.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out dev.crt -days 365
```

### Como usar um usuário criado

Após gerar os certificados, configure o contexto no `kubectl`:

```bash
kubectl config set-credentials dev --client-certificate=dev.crt --client-key=dev.key
kubectl config set-context dev-context --cluster=CLUSTER_NAME --namespace=development --user=dev
kubectl config use-context dev-context
```

Substitua `CLUSTER_NAME` pelo nome do seu cluster.

### Exemplo prático de RBAC

Vamos criar um exemplo prático simples para entender o RBAC. Imagine que precisamos criar uma Role que permita ao usuário "dev" acessar e listar pods apenas no namespace "development".

#### Passo 1: Criar a Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

#### Passo 2: Criar o RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: development
  name: read-pods-binding
subjects:
- kind: User
  name: dev
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Exemplo avançado: ClusterRole para administradores

Caso precise dar permissão em nível de cluster (todos os namespaces), crie um ClusterRole:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin-readonly
rules:
- apiGroups: [""]
  resources: ["pods", "services", "deployments"]
  verbs: ["get", "watch", "list"]
```

E depois associe com um ClusterRoleBinding:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-readonly-binding
subjects:
- kind: User
  name: admin-readonly
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin-readonly
  apiGroup: rbac.authorization.k8s.io
```

### Exercício prático

- Crie uma Role que permita criar e deletar deployments no namespace "teste".
- Associe esta Role ao usuário "operador-teste" com um RoleBinding.

### SecurityContext no Kubernetes: Controlando o ambiente de execução

O `securityContext` no Kubernetes define configurações de segurança que afetam os contêineres e pods em nível de sistema operacional. Ele permite determinar como os processos dentro do contêiner serão executados, influenciando diretamente a segurança e o isolamento dos serviços.

Entre as opções mais comuns de configuração, temos:

- `runAsUser`: Define o UID (user ID) com o qual os processos do contêiner serão executados.
- `runAsGroup`: Define o GID (group ID) com o qual os processos do contêiner serão executados.
- `fsGroup`: Define o grupo proprietário de volumes montados, garantindo que os arquivos sejam acessíveis por processos do contêiner.
- `allowPrivilegeEscalation`: Impede que o processo dentro do contêiner consiga elevar seus privilégios.
- `readOnlyRootFilesystem`: Torna o sistema de arquivos raiz do contêiner somente leitura, aumentando a segurança contra alterações indesejadas.
- `capabilities`: Permite adicionar ou remover capacidades do Linux (como `NET_ADMIN`, `SYS_TIME`, etc), reduzindo a superfície de ataque.

#### Exemplo de uso em um Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: exemplo-securitycontext
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
  - name: app
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html
  volumes:
  - name: shared-data
    emptyDir: {}
```

Nesse exemplo:

- O contêiner roda como o usuário 1000 e grupo 3000.
- O grupo de arquivos (fsGroup) é 2000.
- `allowPrivilegeEscalation` está desativado.
- O sistema de arquivos raiz é somente leitura.
- Todas as capacidades do Linux foram removidas.

Essas medidas ajudam a reduzir drasticamente os riscos de segurança, isolando o processo e limitando o que ele pode fazer dentro do contêiner.

### Conclusão

Entender RBAC é essencial para administrar com segurança os recursos no Kubernetes. Utilize esses conceitos e exemplos para garantir uma gestão eficiente e segura do seu ambiente.
