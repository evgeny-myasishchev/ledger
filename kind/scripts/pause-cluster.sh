#!/usr/bin/env bash

docker ps -f name=ledger -q | xargs -I {} docker pause {}