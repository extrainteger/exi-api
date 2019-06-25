set :application, "your_app_name"

append :linked_files, ".ruby-version", ".env.staging"

set :rvm_type, :auto
set :rvm_ruby_version, 'your_ruby_version' # example: ruby-2.6.3

set :deploy_to, 'your_path_on_server' # example: /home/ubuntu/your_app_name

set :branch, 'staging'
set :rails_env, 'staging'

server "server-ip", user: "server-name", roles: %w{app web db} # example server-ip: 10.10.10.10 server-name: ubuntu

set :ssh_options, {
  forward_agent: false,
  auth_methods: %w(publickey)
 }

 set :keep_releases, 2

 after 'deploy:publishing', 'deploy:restart'
 namespace :deploy do

  task :restart do
    invoke 'unicorn:restart'
  end

end
