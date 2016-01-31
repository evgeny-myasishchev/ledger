#!/bin/bash
set -e

# The script is used as a travis deploy script

# Initialize our own variables:
publish_branch=""
build_number=""
docker_email=""
docker_user=""
docker_password=""

while getopts "h?b:n:e:u:p:" opt; do
    case "$opt" in
    h|\?)
        echo 'Showing help'
        exit 0
        ;;
    b)  publish_branch=$OPTARG
        ;;
    n)  build_number=$OPTARG
        ;;
    e)  docker_email=$OPTARG
        ;;
    u)  docker_user=$OPTARG
        ;;
    p)  docker_password=$OPTARG
        ;;
    esac
done

commit_hash=`git rev-parse --short master`
current_branch=`git rev-parse --abbrev-ref HEAD`

#Using project root as a working dir
cd `dirname $0`/..

: "${publish_branch:?-b <publish_branch> must be provided.}"
: "${build_number:?-n <build-number> must be provided.}"
: "${docker_email:?-e <docker-email> must be provided.}"
: "${docker_user:?-u <docker-user> must be provided.}"
: "${docker_password:?-p <docker-password> must be provided.}"


if [ "${current_branch}" != "${publish_branch}" ]; then
  echo "Current branch '${current_branch}'. Publish branch '${publish_branch}'. Publishing docker image skipped"
  exit 0
fi

IMAGE_TAG=v${build_number}.${commit_hash}

RAILS_ENV=production rake assets:precompile
docker build -t evgenymyasishchev/ledger:"${IMAGE_TAG}" .
docker login -e="$docker_email" -u="$docker_user" -p="$docker_password"
docker push evgenymyasishchev/ledger:"${IMAGE_TAG}"