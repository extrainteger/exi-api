module API::V1::Helpers
  
  # meta response
  def present_metas resources
    total_pages  = resources.count
    limit_value  = params.per_page
    current_page = params.page
    present :meta, { total_pages: total_pages, limit_value: limit_value, current_page: current_page }, with: API::V1::Metas::Entities::Meta
  end

end