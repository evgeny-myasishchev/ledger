# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'ledger'
set :docker_repo, 'evgenymyasishchev/ledger'
server 'my-ledger.com', roles: %w(app), user: fetch(:local_user), port: 2200

# set config below on a per stage basis
# set :config_root, './ledger/env'
# set :web_container, 'ledger-env-web'
# set :web_container_port, 6000
# set :worker_container, 'ledger-env-worker'

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

namespace :deploy do
  desc 'Restart containers'
  task restart: [:stop, :start] do
  end

  task :start do
    invoke 'deploy:worker:start'
    invoke 'deploy:web:start'
  end

  task :stop do
    invoke 'deploy:worker:stop'
    invoke 'deploy:web:stop'
  end

  namespace :worker do
    desc 'Stop worker container'
    task :stop do
      on roles(:app) do
        execute 'docker', 'stop', fetch(:worker_container)
      end
    end

    desc 'Start worker container'
    task :start do
      on roles(:app) do
        execute 'docker', 'start', fetch(:worker_container)
      end
    end
  end

  namespace :web do
    desc 'Stop web container'
    task :stop do
      on roles(:app) do
        execute 'docker', 'stop', fetch(:web_container)
      end
    end

    desc 'Start web container'
    task :start do
      on roles(:app) do
        execute 'docker', 'start', fetch(:web_container)
      end
    end
  end
end

# def createContainer
#   envFile = shipit.config.workspace + '/app.env'
#   port = shipit.config.port
#   repo = shipit.config.dockerRepository
#   container = shipit.config.container
#   shipit.remote([
#     'docker run -d --restart=unless-stopped',
#     '--env-file', envFile,
#     '-p ' + port + ':3000',
#     '--name ', container, repo
#   ].join(' '))
# end
