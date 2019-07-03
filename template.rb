require 'date'

RAILS_REQUIREMENT = "~> 6.0.0.rc1".freeze

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
           "You are using #{rails_version}. Continue anyway? (y/n)"
  exit 1 if no?(prompt)
end

def assert_postgresql
  return if IO.read("Gemfile") =~ /^\s*gem ['"]pg['"]/
  fail Rails::Generators::Error,
       "This template requires PostgreSQL, "\
       "but the pg gem isn’t present in your Gemfile."
end

def add_template_repository_to_source_path
  inside('lib') do
    run "cp -r ../../exi-api ."
    git clone: "--quiet https://github.com/extrainteger/exi-api" unless File.exists? "lib/exi-api"
  end
end 

def ask_doorkeeper
  @doorkeeper = ask("\e[1m \e[32m Do you want to use Doorkeeper & WineBouncer? \e[0m (y / n)") == "y" ? true : false
end

def use_doorkeeper?
  @doorkeeper
end

def ask_capistrano
  @capistrano = ask("\e[1m \e[32m Do you want to use Capistrano? \e[0m (y / n)") == "y" ? true : false
end

def use_capistrano?
  @capistrano
end

# def ask_swagger_theme
#   @grape = ask("\e[1m \e[32m Do you want to use grape-swagger custom theme? \e[0m (y / n)") == "y" ? true : false
# end

# def use_grape_theme?
#   @grape
# end

def apply_template!
  assert_minimum_rails_version
  assert_postgresql
  ask_doorkeeper
  ask_capistrano
  # ask_swagger_theme
  add_template_repository_to_source_path
end

def add_dependencies
  gem_group :development, :test do
    gem 'rspec-rails', '~> 3.5'
    gem 'webmock'
    gem 'guard-rspec', require: false
    gem 'factory_bot_rails'
    gem 'faker'
  end

  if use_capistrano?
    gem_group :development do
      gem 'capistrano'
      gem 'capistrano-rails'
      gem 'capistrano3-unicorn'
      gem 'capistrano-rvm'
      gem 'capistrano-unicorn-monit', github: 'bypotatoes/capistrano-unicorn-monit'
    end

    gem_group :staging do
      gem 'unicorn'
    end
  
    gem_group :production do
      gem 'unicorn'
    end
  end
  
  gem_group :test do
    gem 'database_cleaner'
  end
  
  gem 'devise'
  gem 'activeadmin'
  gem "active_material", github: "vigetlabs/active_material"
  
  gem 'seed_migration'
  
  gem 'grape'
  gem 'grape-middleware-logger'
  gem 'grape-entity'
  
  gem 'hashie-forbidden_attributes'
  gem 'hashdiff', ['>= 1.0.0.beta1', '< 2.0.0']
  
  gem 'rack-cors'
  
  gem 'pagy'
  gem 'api-pagination', github: "extrainteger/api-pagination"
  
  gem 'grape-swagger'
  gem 'grape-swagger-rails'
  gem 'grape-swagger-rails-themes'

  if use_doorkeeper?
    gem 'doorkeeper' 
    gem 'wine_bouncer', '~> 1.0.4'
  end
end

def install_dependencies
  generate "active_admin:install"
  rails_command "seed_migration:install:migrations"
  generate "rspec:install"
  generate "grape_swagger_rails_themes:install"

  if use_doorkeeper?
    generate "doorkeeper:install"
    gsub_file "config/routes.rb", "use_doorkeeper", ""
    generate "doorkeeper:migration"

    generate "wine_bouncer:initializer"
  end
end

def prepare_doorkeeper
  if use_doorkeeper?
    gsub_file "config/initializers/doorkeeper.rb", "# api_only", "api_only"
    gsub_file "config/initializers/doorkeeper.rb", "# grant_flows %w[authorization_code client_credentials]", "grant_flows %w[client_credentials]"
    gsub_file "config/initializers/doorkeeper.rb", "# default_scopes  :public", "default_scopes  :public"
    insert_into_file "config/initializers/doorkeeper.rb", "\n\n  custom_access_token_expires_in do |context| \n    case context.grant_type \n    when 'client_credentials' \n       Float::INFINITY \n    else \n      2.hours \n    end \n  end \n", after: "# access_token_expires_in 2.hours"

    migration = Dir["db/migrate/*_create_doorkeeper_tables.rb"].last
    gsub_file migration, "t.references :resource_owner,  null: false", "t.uuid :resource_owner_id, null: false"
    gsub_file migration, "t.references :resource_owner, index: true", "t.uuid :resource_owner_id"
    insert_into_file migration, "\n    add_index :oauth_access_tokens, :resource_owner_id", after: "add_index :oauth_access_tokens, :token, unique: true"

    gsub_file "config/initializers/wine_bouncer.rb", "config.auth_strategy = :default", "config.auth_strategy = :swagger"
  end
end

def prepare_environment
  run 'cp config/environments/production.rb config/environments/staging.rb'
  run 'cp config/webpack/production.js config/webpack/staging.js'
end

def postgre_uuid
  environment do <<-RUBY
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
  RUBY
  end
  file "db/migrate/#{Time.now.strftime("%Y%m%d%H%M%S")}_enable_uuid_extension.rb", <<-RUBY
class EnableUuidExtension < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'uuid-ossp'
    enable_extension 'pgcrypto'
  end
end  
  RUBY
end

def boilerplate_models
  generate :model, "app_version", "name version_code:integer force_update:boolean"

  file "db/data/#{Time.now.strftime("%Y%m%d%H%M%S")}_add_initial_version.rb", <<-RUBY
class AddInitialVersion < SeedMigration::Migration
  def up
    AppVersion.create name: "Genesis", version_code: "0.0.0", force_update: false
  end

  def down

  end
end    
  RUBY

  generate :model, "user", "email provider uid" if use_doorkeeper?
end

def boilerplate_dashboard
  run 'mv app/assets/stylesheets/active_admin.scss app/assets/stylesheets/active_admin.scss.ori'
  run 'mv app/assets/javascripts/active_admin.js app/assets/javascripts/active_admin.js.ori'
  run 'cp lib/exi-api/app/assets/stylesheets/active_admin.scss app/assets/stylesheets'
  run 'cp lib/exi-api/app/assets/javascripts/active_admin.js app/assets/javascripts'

  environment 'config.hosts << "dashboard.lvh.me"', env: 'development'

  generate "active_admin:resource app_version"

  insert_into_file "app/admin/app_versions.rb", "\n  permit_params :name, :version_code, :force_update", after: "ActiveAdmin.register AppVersion do"
end

def boilerplate_api
  file 'app/controllers/api_controller.rb', <<-RUBY
    class ApiController < ActionController::API
    end
  RUBY
  
  inside 'app/controllers' do
    run 'mkdir API'
    run 'mkdir API/v1'
  end
  run 'cp lib/exi-api/app/controllers/API/error_formatter.rb app/controllers/API/error_formatter.rb'
  template "#{destination_root}/lib/exi-api/app/controllers/API/init.rb.erb", 'app/controllers/API/init.rb'
  run 'cp lib/exi-api/app/controllers/API/success_formatter.rb app/controllers/API/success_formatter.rb'
  run 'cp -r lib/exi-api/app/controllers/API/v1 app/controllers/API'

  if use_doorkeeper?
    run 'cp lib/exi-api/app/controllers/API/oauth.rb app/controllers/API/oauth.rb' 
    insert_into_file "app/controllers/API/v1/main.rb", "\nrequire 'doorkeeper/grape/helpers'", after: 'require "grape-swagger"'
    insert_into_file "app/controllers/API/v1/main.rb", "\n\n      helpers Doorkeeper::Grape::Helpers", after: "include API::V1::Config"
    insert_into_file "app/controllers/API/v1/main.rb", "\n      use ::WineBouncer::OAuth2", after: "helpers Doorkeeper::Grape::Helpers"
  end
end

def prepare_rspec
  run 'mkdir spec/support'
  run 'cp lib/exi-api/spec/support/json_response_reader.rb spec/support/json_response_reader.rb'
  run 'mv spec/rails_helper.rb spec/rails_helper.rb.ori'
  run 'cp lib/exi-api/spec/rails_helper.rb spec/rails_helper.rb'
end

def write_routes
  run 'cp config/routes.rb config/routes.rb.ori'

  gsub_file "config/routes.rb", "devise_for :admin_users, ActiveAdmin::Devise.config", ""
  gsub_file "config/routes.rb", "ActiveAdmin.routes(self)", ""
  route 'mount API::Init, at: "/"'
  route 'mount GrapeSwaggerRails::Engine, as: "doc", at: "/doc"'
  route <<-RUBY
  constraints subdomain: Rails.application.credentials.subdomain[:dashboard] do
    devise_for :admin_users, ActiveAdmin::Devise.config
    ActiveAdmin.routes(self)
  end
  RUBY
  route 'use_doorkeeper' if use_doorkeeper?
end

def override_database_yml
  run 'rm config/database.yml'
  run 'cp lib/exi-api/config/database.yml config/database.yml'
end

def copy_initializers
  run 'cp -r lib/exi-api/config/initializers/. config/initializers'
end

def prepare_capistrano
  run "bundle exec cap install" if use_capistrano?
end

def webpacker
  insert_into_file "config/webpacker.yml", "\n\nstaging:\n  <<: *default\n\n  compile: false\n\n  extract_css: true\n\n  cache_manifest: true", after: "  public_output_path: packs-test"
end

def setup_capistrano
  if use_capistrano?
    # Capfile
    gsub_file 'Capfile', '# require "capistrano/rvm"', 'require "capistrano/rvm"'
    gsub_file 'Capfile', '# require "capistrano/bundler"', 'require "capistrano/bundler"'
    gsub_file 'Capfile', '# require "capistrano/rails/assets"', 'require "capistrano/rails/assets"'
    gsub_file 'Capfile', '# require "capistrano/rails/migrations"', 'require "capistrano/rails/migrations"'
    insert_into_file "Capfile", "\nrequire 'capistrano/seed_migration_tasks'", after: '# require "capistrano/passenger"'
    insert_into_file "Capfile", "\nrequire 'capistrano3/unicorn'", after: "require 'capistrano/seed_migration_tasks'"
    insert_into_file "Capfile", "\nrequire 'capistrano/unicorn/monit'", after: "require 'capistrano3/unicorn'"

    # deploy.rb
    gsub_file "config/deploy.rb", '# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"', 'append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"'
    insert_into_file "config/deploy.rb", "\n\nafter 'deploy:migrating', 'seed:migrate'", after: "# set :ssh_options, verify_host_key: :secure"
    
    # config/deploy/
    run 'rm config/deploy/staging.rb'
    run 'rm config/deploy/production.rb'
    run 'cp lib/exi-api/config/deploy/staging.rb config/deploy/example.rb'

    # config/unicorn
    run 'mkdir config/unicorn'
    run 'cp lib/exi-api/config/unicorn/production.rb config/unicorn/example.rb'
  end
end

def add_gitignore
  # insert_into_file ".gitignore", "\n\n/config/deploy/production.rb \n\n/config/unicorn/production.rb \n/config/unicorn/staging.rb \n\n/config/credentials/staging.key \n/config/credentials/staging.yml.enc \n\n/config/credentials/production.key \n/config/credentials/production.yml.enc", after: ".yarn-integrity"
  insert_into_file ".gitignore", "\n\n/config/deploy/production.rb \n\n/config/unicorn/production.rb \n/config/unicorn/staging.rb \n\n/config/credentials/staging.key \n\n/config/credentials/production.key", after: ".yarn-integrity"
end

def stop_spring
  run "spring stop"
end

def remove_source
  run `rm -rf lib/exi-api`
end

def finishing
  run "cp lib/exi-api/readme.md boilerplate.md"

  say
  say
  say "================================================================================================="
  say 
  say 
  say "You have successfully installed the boilerplate", :green
  say
  say "Don't forget to store your credentials inside config/credentials/*.key into somewhere else safely"
  say
  say "If you lose those keys, you won't be able to read your credentials.", :red
  say
  say
  say "To get started :", :green
  say
  say "Follow the instruction https://github.com/extrainteger/exi-api/blob/master/readme.md#getting-started", :green
  say
  say
  say "================================================================================================="
end


# Main recipe
apply_template!
add_template_repository_to_source_path
add_dependencies
postgre_uuid

after_bundle do
  stop_spring
  install_dependencies
  prepare_rspec
  prepare_doorkeeper
  boilerplate_models
  boilerplate_dashboard
  boilerplate_api
  write_routes
  override_database_yml
  prepare_environment
  copy_initializers
  prepare_capistrano
  setup_capistrano
  webpacker
  add_gitignore
  finishing
  stop_spring
  remove_source
end