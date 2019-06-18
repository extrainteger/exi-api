module API::V1
  module SharedParams
    extend Grape::API::Helpers
  
    params :order do |options|
      optional :order_by, type: String, values: options[:order_by], default: options[:default_order_by]
      optional :direction, type: String, values: ["", "asc", "desc"], default: options[:default_order]
    end

  end
end