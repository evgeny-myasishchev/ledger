roles :app

set :config_root, './ledger/stage'
set :web_container, 'ledger-staging-web'
set :web_container_port, 6000
set :worker_container, 'ledger-staging-worker'
