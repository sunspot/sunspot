module Sunspot
  class Search
    attr_reader :builder

    def initialize(connection, configuration, *types, &block)
      @connection = connection
      params = types.last.is_a?(Hash) ? types.pop : {}
      @query = Sunspot::Query.new(types, params, configuration)
      @builder = build_with(::Sunspot::Builder::StandardBuilder, params)
      @query.dsl.instance_eval(&block) if block
      @types = types
    end

    def build_with(builder_class, *args)
      @query.build_with(builder_class, *args)
    end

    def execute!
      query_options = {}
      query_options[:filter_queries] = @query.scope_queries
      query_options[:rows] = @query.rows
      query_options[:start] = @query.start if @query.start
      query_options[:sort] = @query.sort if @query.sort
      @solr_result = @connection.query(@query.to_solr, query_options)
      self
    end

    def results
      @results ||= if @query.page && defined?(WillPaginate::Collection)
        WillPaginate::Collection.create(@query.page, @query.per_page, @solr_result.total_hits) do |pager|
          pager.replace(result_objects)
        end
      else
        result_objects
      end
    end

    def total
      @total ||= @solr_result.total_hits
    end

    private

    def result_objects
      hit_ids = @solr_result.hits.map { |hit| hit['id'] }
      hit_ids.inject({}) do |type_id_hash, hit_id|
        match = /([^ ]+) (.+)/.match hit_id
        (type_id_hash[match[1]] ||= []) << match[2]
        type_id_hash
      end.inject([]) do |results, pair|
        type_name, ids = pair
        results.concat ::Sunspot::Adapters::DataAccessor.create(type_with_name(type_name)).load_all(ids)
      end.sort_by do |result|
        hit_ids.index(::Sunspot::Adapters::InstanceAdapter.adapt(result).index_id)
      end
    end

    def type_with_name(type_name)
      @types_cache ||= {}
      @types_cache[type_name] ||= type_name.split('::').inject(Module) { |namespace, name| namespace.const_get(name) }
    end
  end
end
