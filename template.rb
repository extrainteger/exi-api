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
    run "cp -r ../../exi-monolith ."
    git clone: "--quiet https://github.com/extrainteger/exi-monolith" unless File.exists? "lib/exi-monolith"
  end
end 

def apply_template!
  assert_minimum_rails_version
  assert_postgresql
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
end

def install_dependencies
  generate "active_admin:install"
  rails_command "seed_migration:install:migrations"
  generate "rspec:install"
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
end

def boilerplate_dashboard
  run 'mv app/assets/stylesheets/active_admin.scss app/assets/stylesheets/active_admin.scss.ori'
  run 'mv app/assets/javascripts/active_admin.js app/assets/javascripts/active_admin.js.ori'
  run 'cp lib/exi-monolith/app/assets/stylesheets/active_admin.scss app/assets/stylesheets'
  run 'cp lib/exi-monolith/app/assets/javascripts/active_admin.js app/assets/javascripts'

  environment 'config.hosts << "dashboard.lvh.me"', env: 'development'

  generate "active_admin:resource app_version"

  insert_into_file "app/admin/app_versions.rb", "\n  permit_params :name, :version_code, :force_update", after: "ActiveAdmin.register AppVersion do"
end

def boilerplate_api
  file 'app/controllers/api_controller.rb', <<-RUBY
    class ApiController < ActionController::API
    end
  RUBY
  
  run 'cp -r lib/exi-monolith/app/controllers/API app/controllers/API'
end

def prepare_rspec
  run 'mkdir spec/support'
  run 'cp lib/exi-monolith/spec/support/json_response_reader.rb spec/support/json_response_reader.rb'
  run 'mv spec/rails_helper.rb spec/rails_helper.rb.ori'
  run 'cp lib/exi-monolith/spec/rails_helper.rb spec/rails_helper.rb'
end

def override_routes
  run 'mv config/routes.rb config/routes.rb.ori'
  run 'cp lib/exi-monolith/config/routes.rb config/routes.rb'
end

def override_database_yml
  run 'rm config/database.yml'
  run 'cp lib/exi-monolith/config/database.yml config/database.yml'
end

def copy_initializers
  run 'cp -r lib/exi-monolith/config/initializers config/initializers'
end

def stop_spring
  run "spring stop"
end

def finishing
  run "cp lib/exi-monolith/readme.md boilerplate.md"
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
  boilerplate_models
  boilerplate_dashboard
  boilerplate_api
  override_routes
  override_database_yml
  prepare_environment
  copy_initializers
  finishing
end