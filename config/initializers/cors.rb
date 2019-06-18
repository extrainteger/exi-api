Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    credentials = false
    if Rails.env.test? || Rails.env.development? || Rails.env.staging?
      credentials = false
      origins "*"
    else
      origins "example.com"
    end
    resource '*',
             :headers     => :any,
             :methods     => [:get, :post, :delete, :put],
             :credentials => credentials,
             :max_age     => 0
  end
end