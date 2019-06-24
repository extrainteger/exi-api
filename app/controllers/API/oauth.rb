module API
  class Oauth < Grape::API

    resources :oauth do
      # POST /oauth/token
      desc 'Logging in user and get token for authorization' do
        failure [ { code: 401, message: 'Unauthorized' }, { code: 400, message: 'Bad request' }, { code: 500, message: 'Internal server error' } ]
      end
      params do
        requires :grant_type, type: String, values: %w(refresh_token client_credentials)
        requires :client_id, type: String
        optional :client_secret, type: String
        optional :refresh_token, type: String, desc: '[Refresh token] Your refresh token'
      end
      post :token do
      end

      desc 'Logging out user and revoke token. Always return {} even if your token is invalid !'
      params do
        requires :client_id, type: String
        optional :client_secret, type: String
        optional :token, type: String, desc: 'Your token'
      end
      post :revoke do
      end
    end # resources :oauth


    # Swagger config
    add_swagger_documentation(
      api_version:             'v1',
      doc_version:             'v1',
      hide_documentation_path: true,
      mount_path:              "doc/oauth",
      hide_format:             true,
      info: {
        title: "Your API",
        description: "Your API"
      }
    )
  end
end