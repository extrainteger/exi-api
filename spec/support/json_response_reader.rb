module JSONResponseReader
  def json_response
    ActiveSupport::HashWithIndifferentAccess.new(JSON(response.body))
  end

  def object_response
    Hashie::Mash.new(ActiveSupport::HashWithIndifferentAccess.new(JSON(response.body)))
  end

  def meta_pagination(total = 1, per_page = 100, page = 1)
    ActiveSupport::HashWithIndifferentAccess.new({ pages: { total: total, per_page: per_page, page: page } })
  end
end
