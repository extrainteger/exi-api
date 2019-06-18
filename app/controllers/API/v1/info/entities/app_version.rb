class API::V1::Info::Entities::AppVersion < Grape::Entity
  expose :id
  expose :name
  expose :version_code
  expose :force_update
end
