# !/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. ${SCRIPT_DIR}/setup-docker-env-helpers.sh

postgres_version=9.5.0

env_name=''
env_file=''
ledger_image='evgenymyasishchev/ledger'

while getopts "e:i:f:p:h" opt; do
  case $opt in
    e)
      env_name=$OPTARG
      ;;
    f)
      env_file=$OPTARG
      ;;
    i)
      ledger_image=$OPTARG
      ;;
    p)
      web_port=$OPTARG
      ;;
    h)
      usage
      exit 0
      ;;
  esac
done

: "${env_name:?-e <name> needs to be provided. Use -h for more details.}"
: "${env_file:?-f <path> needs to be provided. Use -h for more details.}"
: "${web_port:?-p <port> needs to be provided. Use -h for more details.}"

network_name=${env_name}
postgres_image=postgres:${postgres_version}
postgres_name=${env_name}-pg
PGPASSWORD=${PGPASSWORD:="`openssl rand -base64 32`"}
beanstalkd_image=beanstalkd
beanstalkd_name=${env_name}-beanstalkd
web_name=${env_name}-web
worker_name=${env_name}-worker

. ${env_file}
: "${GOAUTH_CLIENT_ID:?GOAUTH_CLIENT_ID is not assigned. Please add it to ${env_file}}"
: "${GOAUTH_CLIENT_SECRET:?GOAUTH_CLIENT_SECRET is not assigned. Please add it to ${env_file}}"
: "${DEVISE_SECRET_KEY:?DEVISE_SECRET_KEY is not assigned. Please add it to ${env_file}}"
: "${SECRET_KEY_BASE:?SECRET_KEY_BASE is not assigned. Please add it to ${env_file}}"
: "${SMTP_HOST:?SMTP_HOST is not assigned. Please add it to ${env_file}}"
: "${SMTP_PORT:?SMTP_PORT is not assigned. Please add it to ${env_file}}"
: "${BEANSTALKD_URL:?BEANSTALKD_URL is not assigned. Please add it to ${env_file}}"
: "${LEDGER_PGPASS:?LEDGER_PGPASS is not assigned. Please generate and add to ${env_file}}"

DATABASE_URL=postgresql://ledger:${LEDGER_PGPASS}@${postgres_name}/ledger

echo "Creating docker network ${network_name}"
if [ `docker network ls | awk '{ print $2 }' | grep -w ${network_name} | wc -l` -eq 1 ]; then
  echo 'Network already exists. Ignoring.'
else
  docker network create ${network_name}
fi

postgres_volumes="-v /var/run/${env_name}/pg-data:/var/lib/postgresql/data"
create_docker_container ${postgres_name} ${postgres_image} "${postgres_volumes}"

echo "Creating beanstalkd image: ${beanstalkd_image}"
if [ `docker images --format "{{.Repository}}" | grep -w ${beanstalkd_image} | wc -l` -eq 1 ]; then
  echo "Beanstalkd image already exists."
else
  docker build -t ${beanstalkd_image} -f docker/Dockerfile.beanstalkd docker
fi

create_docker_container ${beanstalkd_name} ${beanstalkd_image}
create_docker_container ${worker_name} "${ledger_image} backburner" "--env-file=${env_file} -e DATABASE_URL=${DATABASE_URL}"
create_docker_container ${web_name} ${ledger_image} "-p ${web_port}:3000 --env-file=${env_file} -e DATABASE_URL=${DATABASE_URL}"

echo "Containers created."
echo "Used passwords:"
echo "* postgres: ${PGPASSWORD}"
echo "* ledger(pg user): ${LEDGER_PGPASS}"
echo "Use following snippets to init containers:"
echo " docker run --rm -it --env-file=${env_file} -e POSTGRES_PASSWORD=${PGPASSWORD} ${postgres_volumes} ${postgres_image}"
echo " docker start ${postgres_name}"
echo " docker run --rm -it --env-file=${env_file} -e DATABASE_URL=${DATABASE_URL} -e PGHOST=${postgres_name} -e PGPASSWORD=${PGPASSWORD} --net=ledger-staging evgenymyasishchev/ledger db-setup"
echo "Use following helpers to start them:"
echo " docker start ${postgres_name}"
echo " docker start ${beanstalkd_name}"
echo " docker start ${worker_name}"
echo " docker start ${web_name}"