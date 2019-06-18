Rails.application.routes.draw do
  constraints subdomain: Rails.application.credentials.subdomain[:dashboard] do
    devise_for :admin_users, ActiveAdmin::Devise.config
    ActiveAdmin.routes(self)
  end

  mount API::Init, at: "/"

  mount GrapeSwaggerRails::Engine, as: "doc", at: "/doc"
end
