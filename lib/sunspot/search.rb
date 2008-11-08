module Sunspot
  class Search
    def initialize(*types, &block)
      params = types.last.is_a?(Hash) ? types.pop : {}
      @query = Sunspot::Query.new(types, params[:keywords], params[:conditions] || {})
      QueryBuilder.new(@query).instance_eval(&block) if block
    end

    def execute!
      @solr_result = connection.query(query.to_solr, :filter_queries => query.filter_queries)
    end

    protected
    attr_reader :query

    private

    def connection
      Solr::Connection.new('http://localhost:8983/solr', true)
    end
  end
end
