require File.join(File.dirname(__FILE__), 'search', 'hit')

module Sunspot
  # 
  # This class encapsulates the results of a Solr search. It provides access
  # to search results, total result count, facets, and pagination information.
  # Instances of Search are returned by the Sunspot.search and
  # Sunspot.new_search methods.
  #
  class Search
    # Query information for this search. If you wish to build the query without
    # using the search DSL, this method allows you to access the query API
    # directly. See Sunspot#new_search for how to construct the search object
    # in this case.
    attr_reader :query 

    def initialize(connection, setup, query) #:nodoc:
      @connection, @setup, @query = connection, setup, query
    end

    #
    # Execute the search on the Solr instance and store the results. If you
    # use Sunspot#search() to construct your searches, there is no need to call
    # this method as it has already been called. If you use
    # Sunspot#new_search(), you will need to call this method after building the
    # query.
    #
    def execute!
      params = @query.to_params
      @solr_result = @connection.select(params)
      self
    end

    # 
    # Get the collection of results as instantiated objects. If WillPaginate is
    # available, the results will be a WillPaginate::Collection instance; if
    # not, it will be a vanilla Array.
    #
    # ==== Returns
    #
    # WillPaginate::Collection or Array:: Instantiated result objects
    #
    def results
      @results ||= if @query.page && defined?(WillPaginate::Collection)
        WillPaginate::Collection.create(@query.page, @query.per_page, total) do |pager|
          pager.replace(result_objects)
        end
      else
        result_objects
      end
    end

    # 
    # Access raw Solr result information. Returns a collection of Hit objects
    # that contain the class name, primary key, keyword relevance score (if
    # applicable), and any stored fields.
    #
    # ==== Returns
    #
    # Array:: Ordered collection of Hit objects
    #
    def hits
      @hits ||= solr_response['docs'].map { |doc| Hit.new(doc, self) }
    end
    alias_method :raw_results, :hits

    # 
    # The total number of documents matching the query parameters
    #
    # ==== Returns
    #
    # Integer:: Total matching documents
    #
    def total
      @total ||= solr_response['numFound']
    end

    # 
    # Get the facet object for the given field. This field will need to have
    # been requested as a field facet inside the search block.
    #
    # ==== Parameters
    #
    # field_name<Symbol>:: field name for which to get the facet
    #
    # ==== Returns
    #
    # Sunspot::Facet:: Facet object for the given field
    #
    def facet(field_name)
      (@facets_cache ||= {})[field_name.to_sym] ||=
        begin
          query_facet(field_name) ||
            begin
              field = field(field_name)
              date_facet(field) ||
                begin
                  facet_class = field.reference ? InstantiatedFacet : Facet
                  facet_class.new(@solr_result['facet_counts']['facet_fields'][field.indexed_name], field)
                end
            end
        end
    end

    # 
    # Get the facet object for a given dynamic field. This dynamic field will
    # need to have been requested as a field facet inside the search block.
    #
    # ==== Parameters
    #
    # base_name<Symbol>::
    #   Base name of the dynamic field definiton (as specified in the setup
    #   block)
    # dynamic_name<Symbol>::
    #   Dynamic field name to facet on
    # 
    # ==== Returns
    #
    # Sunspot::Facet:: Facet object for given dynamic field
    # 
    # ==== Example
    #
    #   search = Sunspot.search(Post) do
    #     dynamic :custom do
    #       facet :cuisine
    #     end
    #   end
    #   search.dynamic_facet(:custom, :cuisine)
    #     #=> Facet for the dynamic field :cuisine in the :custom field definition
    # 
    def dynamic_facet(base_name, dynamic_name)
      (@dynamic_facets_cache ||= {})[[base_name.to_sym, dynamic_name.to_sym]] ||=
        begin
          field = @setup.dynamic_field_factory(base_name).build(dynamic_name)
          Facet.new(@solr_result['facet_counts']['facet_fields'][field.indexed_name], field)
        end
    end

    # 
    # Get the data accessor that will be used to load a particular class out of
    # persistent storage. Data accessors can implement any methods that may be
    # useful for refining how data is loaded out of storage. When building a
    # search manually (e.g., using the Sunspot#new_search method), this should
    # be used before calling #execute(). Use the
    # Sunspot::DSL::Search#data_accessor_for method when building searches using
    # the block DSL.
    #
    def data_accessor_for(clazz)
      (@data_accessors ||= {})[clazz.name.to_sym] ||=
        Adapters::DataAccessor.create(clazz)
    end

    # 
    # Build this search using a DSL block.
    #
    def build(&block) #:nodoc:
      Util.instance_eval_or_call(dsl, &block)
      self
    end

    private

    def solr_response
      @solr_response ||= @solr_result['response']
    end

    # 
    # Collection of instantiated result objects corresponding to the results
    # returned by Solr.
    #
    # ==== Returns
    #
    # Array:: Collection of instantiated result objects
    #
    def result_objects
      hits.inject({}) do |type_id_hash, hit|
        (type_id_hash[hit.class_name] ||= []) << hit.primary_key
        type_id_hash
      end.inject([]) do |results, pair|
        type_name, ids = pair
        data_accessor = data_accessor_for(Util.full_const_get(type_name))
        results.concat(data_accessor.load_all(ids))
      end.sort_by do |result|
        doc_ids.index(Adapters::InstanceAdapter.adapt(result).index_id)
      end
    end

    def doc_ids
      @doc_ids ||= solr_response['docs'].map { |doc| doc['id'] }
    end

    def dsl
      DSL::Search.new(self)
    end

    def raw_facet(field)
      if field.type == Type::TimeType
        @solr_result['facet_counts']['facet_dates'][field.indexed_name]
      end || @solr_result['facet_counts']['facet_fields'][field.indexed_name]
    end

    def date_facet(field)
      if field.type == Type::TimeType
        if @solr_result['facet_counts'].has_key?('facet_dates')
          if facet_result = @solr_result['facet_counts']['facet_dates'][field.indexed_name]
            DateFacet.new(facet_result, field)
          end
        end
      end
    end

    def query_facet(name)
      if query_facet = @query.query_facet(name.to_sym)
        if @solr_result['facet_counts'].has_key?('facet_queries')
          QueryFacet.new(
            query_facet,
            @solr_result['facet_counts']['facet_queries']
          )
        end
      end
    end

    def field(name)
      @setup.field(name)
    end
  end
end
