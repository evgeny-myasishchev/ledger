#!/usr/bin/env bash

set -e

kind delete cluster --name ledger
kind create cluster --config ./resoures/common/ledger-kind-cluster.yaml
kubectl apply -f ./resoures/common -R
kubectl apply -f ./resoures/dashboard -R