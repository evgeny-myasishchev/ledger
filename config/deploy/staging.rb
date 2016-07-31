roles :app

set :config_root, './ledger/stage'
set :web_container, 'ledger-staging-web'
set :web_container_port, 5010
set :worker_container, 'ledger-staging-worker'
set :docker_network, 'ledger-staging'
