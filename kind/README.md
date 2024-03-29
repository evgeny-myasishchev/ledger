# using kind to deploy locally

All commands below must be done from kind folder. It is also assumed that direnv is installed.

## Common infra provisioning

Use a script that will recreate all the common cluster resources (without application specific).
```
recreate-cluster.sh
```

You may want to pause the cluster if not used to avoid constant resources utilisation:
```
# to pause
pause-cluster.sh

# to unpause
unpause-cluster.sh
```

Optionally provision every resource separately as below.

### Provision cluster

Create cluster
```
kind create cluster --config ./resources/ledger-kind-cluster.yaml
```

Delete cluster if you have to recreate
```
kind delete cluster --name ledger
```

### Common

Install common infra that includes ingress controller and local registry.
```
kubectl apply -R -f ./resources/common
```

The ingress template is taken from (here)[https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.5/deploy/static/provider/cloud/deploy.yaml]


## Dashboard

This is optional.

The `00-recommended.yaml` template is taken from (here)[https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml]
```
kubectl apply -f ./resources/dashboard -R
```

Access the dashboard:
```
# kubectl proxy
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

# via ingress
http://localhost:50080/dashboard/#/login
```

Get secret
```
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}" | pbcopy
```

## Images

Build and upload docker image into a local registry:
```
make push-local-images
```

## Services provisioning

Postgres
```
kubectl apply -R -f ./resources/postgres
```

Beanstalkd
```
kubectl apply -R -f ./resources/beanstalk
```

## Ledger