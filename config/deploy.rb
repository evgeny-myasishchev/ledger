# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'ledger'
set :docker_repo, 'evgenymyasishchev/ledger'
server 'my-ledger.com', roles: %w(app), user: fetch(:local_user), port: 2200

# set config below on a per stage basis
# set :config_root, './ledger/env'
# set :web_container, 'ledger-env-web'
# set :web_container_port, 5000
# set :worker_container, 'ledger-env-worker'
# set :docker_network, 'ledger-env'

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

desc 'Deploy new version of ledger containers'
task :deploy do
  on roles(:app) do
    execute 'docker', 'pull', fetch(:docker_repo)
    invoke 'deploy:stop'
    invoke 'deploy:remove_containers'
    invoke 'deploy:create_containers'
  end
end

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

  desc 'Create web and worker Containers'
  task :create_containers do
    invoke 'deploy:worker:create_container'
    invoke 'deploy:web:create_container'
  end

  desc 'Remove web and worker Containers'
  task :remove_containers do
    invoke 'deploy:worker:remove_container'
    invoke 'deploy:web:remove_container'
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

    desc 'Remove worker container'
    task :remove_container do
      on roles(:app) do
        execute 'docker', 'rm', fetch(:worker_container)
      end
    end

    desc 'Create worker container'
    task :create_container do
      on roles(:app) do
        execute [
          'docker run -d --restart=unless-stopped',
          '--env-file', File.join(fetch(:config_root), 'app.env'),
          '--net', fetch(:docker_network),
          '--name', fetch(:worker_container), fetch(:docker_repo), 'backburner'
        ].join(' ')
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

    desc 'Remove web container'
    task :remove_container do
      on roles(:app) do
        execute 'docker', 'rm', fetch(:web_container)
      end
    end

    desc 'Create web container'
    task :create_container do
      on roles(:app) do
        execute [
          'docker run -d --restart=unless-stopped',
          '--env-file', File.join(fetch(:config_root), 'app.env'),
          '-p ', "#{fetch(:web_container_port)}:3000",
          '--net', fetch(:docker_network),
          '--name', fetch(:web_container), fetch(:docker_repo)
        ].join(' ')
      end
    end
  end
end
