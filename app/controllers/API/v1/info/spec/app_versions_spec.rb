require 'rails_helper'

RSpec.describe "API::V1::Info::AppVersion", type: :request do

  describe "[GET] Endpoint /v1/versions/latest" do
    it "Get latest version" do
      get "/v1/versions/latest"
      expect(response.status).to eq(200)
    end
  end

  describe "[GET] Endpoint /v1/versions" do
    it "Get all versions" do
      get "/v1/versions"
      expect(response.status).to eq(200)
      expect(json_response["data"].size).to eq(1)
    end
  end
  
end