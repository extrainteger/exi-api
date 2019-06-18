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
2. Go to project `cd hello`
3. Edit credential `rails credentials:edit --environment development`. Modify the content from [credentials/example.yml](https://github.com/extrainteger/exi-monolith/blob/master/credentials/example.yml)
4. Edit credential `rails credentials:edit --environment test`. Modify the content from [credentials/example.yml](https://github.com/extrainteger/exi-monolith/blob/master/credentials/example.yml)
5. Prepare database `rails db:create && rails db:migrate && rails seed:migrate`

Don't forget to create admin user :

1. Go to rails console `rails c`
2. Execute command `AdminUser.create email: "helmy@extrainteger.com", password: "yunan123", password_confirmation: "yunan123"`

# Testing

Execute `rspec app/controllers/API`

# Access

1. Start server `rails s`
2. Go to http://dashboard.lvh.me:3000/admin to check Dashboard
3. Go to http://localhost:3000/doc to check API


# Todo

Please Read [todo.md](https://github.com/extrainteger/exi-monolith/blob/master/todo.md)



