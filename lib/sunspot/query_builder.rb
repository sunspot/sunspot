module Sunspot
  class QueryBuilder
    def initialize(query)
      @query = query 
    end

    def keywords(keywords)
      @query.keywords = keywords
    end

    def with
      @conditions_builder ||= ::Sunspot::ScopeBuilder.new(@query)
    end

    def conditions
      @query.conditions
    end
  end
end
