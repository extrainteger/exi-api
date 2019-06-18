module API
  module V1
    class ApiResource < Grape::API
      # Exception Handlers
      include API::V1::ExceptionHandlers
      
      AUTHORIZATION_HEADERS = { Authorization: { description: 'Access Token', required: true } }.freeze
    end
  end
end
  