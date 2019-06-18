require "grape-swagger"

module API
  module V1
    class Main < Grape::API
      # Default Config API
      include API::V1::Config

      # Exception Handlers
      include API::V1::ExceptionHandlers

      # Mounting Modules
      mount API::V1::Info::Routes

      # Swagger config
      add_swagger_documentation(
          api_version:             'not set',
          doc_version:             'not set',
          hide_documentation_path: true,
          mount_path:              "doc/api",
          hide_format:             true,
          array_use_braces:        true,
          info: {
              title: "Your API",
              description: "Your API"
          }
      )
    end
  end
end