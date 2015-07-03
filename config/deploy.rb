# config valid only for Capistrano 3.4.0
lock '3.4.0'

set :application, 'juntos.podemos.info'
set :repo_url, 'git@github.com:podemos-info/podemos-participa.git'
set :linked_files, %w{config/database.yml config/secrets.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system db/podemos}
