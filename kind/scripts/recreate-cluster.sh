#!/usr/bin/env bash

set -e

kind delete cluster --name ledger
kind create cluster --config ./resources/ledger-kind-cluster.yaml
kubectl apply -f ./resources/common -R
kubectl apply -f ./resources/dashboard -R