module Sunspot
  class Search
    def initialize(*types, &block)
      params = types.last.is_a?(Hash) ? types.pop : {}
      @query = Sunspot::Query.new(types, params[:keywords], params[:conditions] || {})
      QueryBuilder.new(@query).instance_eval(&block) if block
    end

    def execute!
      query_options = {}
      query_options[:filter_queries] = query.filter_queries
      query_options[:rows] = query.rows if query.rows
      query_options[:start] = query.start if query.start
      @solr_result = connection.query(query.to_solr, query_options)
    end

    protected
    attr_reader :query

    private

    def connection
      Solr::Connection.new('http://localhost:8983/solr', true)
    end
  end
end
