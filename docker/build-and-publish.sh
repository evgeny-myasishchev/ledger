#!/bin/bash
set -e

# The script is used as a travis deploy script

#Using project root as a working dir
cd `dirname $0`/..

: "${TRAVIS_BUILD_NUMBER:?TRAVIS_BUILD_NUMBER env has not been assigned.}"
: "${DOCKER_EMAIL:?DOCKER_EMAIL env has not been assigned.}"
: "${DOCKER_USER:?DOCKER_USER env has not been assigned.}"
: "${DOCKER_PASSWORD:?DOCKER_PASSWORD env has not been assigned.}"
HEAD_HASH=`git rev-parse --short HEAD`
IMAGE_TAG=v${TRAVIS_BUILD_NUMBER}.${HEAD_HASH}

RAILS_ENV=production rake assets:precompile
docker build -t evgenymyasishchev/ledger:"${IMAGE_TAG}" .
docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USER" -p="$DOCKER_PASSWORD"
docker push evgenymyasishchev/ledger

