module Sunspot
  class QueryBuilder
    def initialize(query)
      @query = query 
    end

    def keywords(keywords)
      @query.keywords = keywords
    end
  end
end
