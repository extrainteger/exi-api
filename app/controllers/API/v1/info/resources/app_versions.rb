module API::V1::Info::Resources
  class AppVersions < API::V1::ApiResource
    helpers API::V1::Helpers

    resource "versions" do

      desc 'version' do
        detail 'latest version'
      end
      get "/latest" do
        version = AppVersion.order(version_code: :desc).last

        present :version, version, with: API::V1::Info::Entities::AppVersion
      end

      desc 'all versions' do
        detail 'all versions'
      end
      paginate
      get "/" do
        records = AppVersion.order(version_code: :desc)
        versions = paginate records

        present :versions, versions, with: API::V1::Info::Entities::AppVersion
      end
      
    end

  end
end