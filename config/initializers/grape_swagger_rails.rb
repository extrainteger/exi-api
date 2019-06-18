GrapeSwaggerRails.options.before_action do |request|
  unless Rails.env.development?
    unless user = authenticate_with_http_basic { |u, p| u == Rails.application.credentials.api_doc[:username] && p == Rails.application.credentials.api_doc[:password] }
      request_http_basic_authentication
    end
  end
end