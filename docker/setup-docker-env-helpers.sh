function usage {
  echo Usage: setup-docker-env.sh -e [name]
  echo Setup docker based ledger environment:
  echo "* Creates docker network named [name]"
  echo "* Creates [name]-pg postgres container"
  echo "* Creates [name]-beanstalkd container"
  echo "* Creates [name]-web ledger container"
  echo "* Creates [name]-worker ledger container"
  echo ""
  echo "Options:"
  echo "  -e <name>   name of the environment. Example: ledger-staging."
  echo "  -f <path>   file path with environment variables for web and worker containers."
  echo "  -h          show this help message."
}

function create_docker_container {
  container_name=$1
  image_name=$2
  args=$3
  default_container_args="--net=${network_name} --hostname=${container_name} --name ${container_name}"
  echo "Creating container: ${container_name}"
  if [ `docker ps -a --filter "name=${container_name}" | wc -l` -eq 2 ]; then
    echo "Container ${container_name} already exists. Ignoring."
  else
    docker create ${default_container_args} ${args} ${image_name}
  fi
}
