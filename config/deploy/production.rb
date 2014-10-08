role :app, %w{capistrano@juntos.podemos.info}
role :web, %w{capistrano@juntos.podemos.info}
role :db,  %w{capistrano@juntos.podemos.info}

set :branch, :production
set :deploy_to, '/var/www/participa.podemos.info'

after 'deploy:publishing', 'deploy:restart'
namespace :deploy do
  task :start do
    on roles(:app) do
      execute "/etc/init.d/unicorn_production start"
    end
  end
  task :stop do
    on roles(:app) do
      execute "/etc/init.d/unicorn_production stop"
    end
  end
  task :restart do
    on roles(:app) do
      execute "/etc/init.d/unicorn_production restart"
    end
  end
end
