roles :app

set :config_root, './ledger/prod'
set :web_container, 'ledger-prod-web'
set :web_container_port, 5510
set :worker_container, 'ledger-prod-worker'
set :docker_network, 'ledger-prod'
