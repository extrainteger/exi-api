# Boilerplate

The purpose of this [template](https://github.com/extrainteger/exi-monolith/blob/master/readme.md) is to accomodate monolith API project including its dashboard.

The boilerplate contains :

1. ActiveAdmin
2. Grape 
3. Swagger
4. Rspec

# Dependencies

1. Rails 6.0.0.rc1 or newer
2. Postgresql

# Install

Assume we want to create a project named `Hello`

1. Create a new rails project `rails new hello -m https://raw.githubusercontent.com/extrainteger/exi-monolith/master/template.rb -d postgresql`
2. While installing in progress you will be asked some question

## Doorkeeper

`Do you want to use Doorkeeper & WineBouncer?` 

Answer `y` if you wish to use Doorkeeper

## Capistrano

`Do you want to use Capistrano?`

Answer `y` if you wish to use Capistrano

# Getting started

1. Go to project `cd hello`
2. Edit credential `rails credentials:edit --environment development`. Modify the content from [credentials/example.yml](https://github.com/extrainteger/exi-monolith/blob/master/credentials/example.yml)
3. Edit credential `rails credentials:edit --environment test`. Modify the content from [credentials/example.yml](https://github.com/extrainteger/exi-monolith/blob/master/credentials/example.yml)
4. Prepare database `rails db:create && rails db:migrate && rails seed:migrate`

# Dashboard

Create default admin user from your `rails c` :
```ruby
AdminUser.create email: "helmy@extrainteger.com", password: "yunan123", password_confirmation: "yunan123"
```

# Testing

Execute :
```ruby
rspec app/controllers/API
```

# Access

1. Start server `rails s`
2. Go to http://dashboard.lvh.me:3000/admin to check Dashboard
3. Go to http://localhost:3000/doc to check API


# Authorization

If you use Doorkeeper, the template will set **public** as a default scope. The template uses Oauth 2.0 as an authorization and use 2 strategy :
1. Application context (Client credential flow)
2. User context (You need to choose and implement by yourself)

All of your API endpoint must be protected at least using application context.

## Generate access token

1. From your `rails c`, create your first application :

    ```ruby
    Doorkeeper::Application.create name: "MyApp", redirect_uri: "urn:ietf:wg:oauth:2.0:oob", confidential: true
    client_id = Doorkeeper::Application.last.uid
    client_secret = Doorkeeper::Application.last.secret
    ```

2. Change API Doc URL to : **http://localhost:3000/doc/oauth**

    ![API Doc URL](images/api_doc.png)

3. Create access token using :
   - grant_type : **client_credential**
   - client_id
   - client_secret


## Protecting your endpoint

You need 2 steps to protect your endpoint :
1. Add scope
2. Add header

Use :
1. `oauth2` to protect with default scope
2. `oauth2 "public"` to protect with public scope
3. `oauth2 "your_scope your_another_scope"` to protect with specific scope(s) 

Add headers inside your API description block `headers AUTHORIZATION_HEADERS`.

Example :

```ruby
desc 'Your protected endpoint' do
  detail 'Your protected endpoint'
  headers AUTHORIZATION_HEADERS
end
oauth2
get "/hello" do
  { hello: :world }
end
```

# Capistrano

If you choose Capistrano as your deployment tool, you just have to modify these 2 files `staging.rb` & `production.rb` inside config/deploy folder, both files are have the same source code except for the value.

## What should I modified?
1. `set :application, "your_app_name"`
2. `set :rvm_ruby_version, 'your_ruby_version' # example: ruby-2.5.3`
3. `set :deploy_to, 'your_path_on_server' # example: /home/ubuntu/your_app_name`
4. `server "server-ip", user: "server-name", roles: %w{app web db} # example [server-ip: 10.10.10.10, server-name: ubuntu]`

## Notes:
Currently, the default setting of Capistrano is set to unicorn, in the next release we'll made an options so that user can choose what tools they would like to use.

# Todo

Please Read [todo.md](https://github.com/extrainteger/exi-monolith/blob/master/todo.md)



