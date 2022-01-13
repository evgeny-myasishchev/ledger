#!/usr/bin/env bash

set -e

kind delete cluster --name ledger
kind create cluster --config ./resources/ledger-kind-cluster.yaml
kubectl apply -f ./resources/common -R
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
kubectl apply -f ./resources/dashboard -R