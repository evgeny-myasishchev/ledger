#!/usr/bin/env bash

set -e

kind delete cluster --name ledger
kind create cluster --config ledger-cluster.yaml
kubectl apply -f ./dashboard -R