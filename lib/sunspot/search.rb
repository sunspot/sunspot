%w(query_facet field_facet date_facet facet_row hit
   highlight).each do |file|
  require File.join(File.dirname(__FILE__), 'search', file)
end

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

    def initialize(connection, setup, query, configuration) #:nodoc:
      @connection, @setup, @query = connection, setup, query
      @query.paginate(1, configuration.pagination.default_per_page)
      @facets = {}
    end

    #
    # Execute the search on the Solr instance and store the results. If you
    # use Sunspot#search() to construct your searches, there is no need to call
    # this method as it has already been called. If you use
    # Sunspot#new_search(), you will need to call this method after building the
    # query.
    #
    def execute
      reset
      params = @query.to_params
      @solr_result = @connection.select(params)
      self
    end
    alias_method :execute!, :execute #:nodoc: deprecated

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
          pager.replace(hits.map { |hit| hit.instance })
        end
      else
        hits.map { |hit| hit.instance }
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
      @hits ||= solr_response['docs'].map { |doc| Hit.new(doc, highlights_for(doc), self) }
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
    # Get the facet object for the given name. `name` can either be the name
    # given to a query facet, or the field name of a field facet. Returns a
    # Sunspot::Facet object.
    #
    def facet(name)
      @facets[name]
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
      facet(:"#{base_name}:#{dynamic_name}")
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
    def data_accessor_for(clazz) #:nodoc:
      (@data_accessors ||= {})[clazz.name.to_sym] ||=
        Adapters::DataAccessor.create(clazz)
    end

    # 
    # Build this search using a DSL block. This method can be called more than
    # once on an unexecuted search (e.g., Sunspot.new_search) in order to build
    # a search incrementally.
    #
    # === Example
    #
    #   search = Sunspot.new_search(Post)
    #   search.build do
    #     with(:published_at).less_than Time.now
    #   end
    #   search.execute!
    #
    def build(&block)
      Util.instance_eval_or_call(dsl, &block)
      self
    end

    # 
    # Populate the Hit objects with their instances. This is invoked the first
    # time any hit has its instance requested, and all hits are loaded as a
    # batch.
    #
    def populate_hits! #:nodoc:
      id_hit_hash = Hash.new { |h, k| h[k] = {} }
      hits.each do |hit|
        id_hit_hash[hit.class_name][hit.primary_key] = hit
      end
      id_hit_hash.each_pair do |class_name, hits|
        ids = hits.map { |id, hit| hit.primary_key }
        data_accessor_for(Util.full_const_get(class_name)).load_all(ids).each do |instance|
          hit = id_hit_hash[class_name][Adapters::InstanceAdapter.adapt(instance).id.to_s]
          hit.instance = instance
        end
      end
    end

    def inspect #:nodoc:
      "<Sunspot::Search:#{query.to_params.inspect}>"
    end

    def add_field_facet(field, options = {}) #:nodoc:
      @facets[field.name] = FieldFacet.new(field, self, options)
    end

    def add_date_facet(field, options) #:nodoc:
      @facets[field.name] = DateFacet.new(field, self, options)
    end

    def add_query_facet(name, options) #:nodoc:
      @facets[name] = QueryFacet.new(name, self, options)
    end

    def facet_response #:nodoc:
      @solr_result['facet_counts']
    end

    private

    def solr_response
      @solr_response ||= @solr_result['response']
    end

    def dsl
      DSL::Search.new(self, @setup)
    end

    def highlights_for(doc)
      if @solr_result['highlighting']
        @solr_result['highlighting'][doc['id']]
      end
    end
    
    # Clear out all the cached ivars so the search can be called again.
    def reset
      @results = @hits = @total = @solr_response = @doc_ids = nil
    end
  end
end
