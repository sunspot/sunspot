require 'sunspot/search/paginated_collection'
require 'sunspot/search/hit_enumerable'

module Sunspot
  module Search #:nodoc:
    
    # 
    # This class encapsulates the results of a Solr search. It provides access
    # to search results, total result count, facets, and pagination information.
    # Instances of Search are returned by the Sunspot.search and
    # Sunspot.new_search methods.
    #
    class AbstractSearch
      # 
      # Retrieve all facet objects defined for this search, in order they were
      # defined. To retrieve an individual facet by name, use #facet()
      #
      attr_reader :facets, :groups
      attr_reader :query #:nodoc:
      attr_accessor :request_handler

      include HitEnumerable
  
      def initialize(connection, setup, query, configuration) #:nodoc:
        @connection, @setup, @query = connection, setup, query
        @query.paginate(1, configuration.pagination.default_per_page)

        @facets = []
        @facets_by_name = {}

        @groups_by_name = {}
        @groups = []
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
        @solr_result = @connection.post "#{request_handler}", :data => params
        self
      end

      def execute! #:nodoc: deprecated
        execute
      end
  
      # 
      # Get the collection of results as instantiated objects. If WillPaginate is
      # available, the results will be a WillPaginate::Collection instance; if
      # not, it will be a vanilla Array.
      #
      # If not all of the results referenced by the Solr hits actually exist in
      # the data store, Sunspot will only return the results that do exist.
      #
      # ==== Returns
      #
      # WillPaginate::Collection or Array:: Instantiated result objects
      #
      def results
        @results ||= paginate_collection(verified_hits.map { |hit| hit.instance })
      end
  
      # 
      # Access raw Solr result information. Returns a collection of Hit objects
      # that contain the class name, primary key, keyword relevance score (if
      # applicable), and any stored fields.
      #
      # ==== Options (options)
      #
      # :verify::
      #   Only return hits that reference objects that actually exist in the data
      #   store. This causes results to be eager-loaded from the data store,
      #   unlike the normal behavior of this method, which only loads the
      #   referenced results when Hit#result is first called.
      #
      # ==== Returns
      #
      # Array:: Ordered collection of Hit objects
      #
      def hits(options = {})
        if options[:verify]
          super
        else
          @hits ||= paginate_collection(super)
        end
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
        @total ||= solr_response['numFound'] || 0
      end
  
      # 
      # The time elapsed to generate the Solr response
      #
      # ==== Returns
      #
      # Integer:: Query runtime in milliseconds
      #
      def query_time
        @query_time ||= solr_response_header['QTime']
      end
  
      # 
      # Get the facet object for the given name. `name` can either be the name
      # given to a query facet, or the field name of a field facet. Returns a
      # Sunspot::Facet object.
      #
      # ==== Parameters
      #
      # name<Symbol>::
      #   Name of the field to return the facet for, or the name given to the
      #   query facet when the search was constructed.
      # dynamic_name<Symbol>::
      #   If faceting on a dynamic field, this is the dynamic portion of the field
      #   name.
      #
      # ==== Example:
      #
      #   search = Sunspot.search(Post) do
      #     facet :category_ids
      #     dynamic :custom do
      #       facet :cuisine
      #     end
      #     facet :age do
      #       row 'Less than a month' do
      #         with(:published_at).greater_than(1.month.ago)
      #       end
      #       row 'Less than a year' do
      #         with(:published_at, 1.year.ago..1.month.ago)
      #       end
      #       row 'More than a year' do
      #         with(:published_at).less_than(1.year.ago)
      #       end
      #     end
      #   end
      #   search.facet(:category_ids)
      #     #=> Facet for :category_ids field
      #   search.facet(:custom, :cuisine)
      #     #=> Facet for the dynamic field :cuisine in the :custom field definition
      #   search.facet(:age)
      #     #=> Facet for the query facet named :age
      #
      def facet(name, dynamic_name = nil)
        if name
          if dynamic_name
            @facets_by_name[:"#{name}:#{dynamic_name}"]
          else
            @facets_by_name[name.to_sym]
          end
        end
      end

      def group(name)
        if name
          @groups_by_name[name.to_sym]
        end
      end
  
      # 
      # Deprecated in favor of optional second argument to #facet
      #
      def dynamic_facet(base_name, dynamic_name) #:nodoc:
        facet(base_name, dynamic_name)
      end
  
      def facet_response #:nodoc:
        @solr_result['facet_counts']
      end

      def group_response #:nodoc:
        @solr_result['grouped']
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
      #   search.execute
      #
      def build(&block)
        Util.instance_eval_or_call(dsl, &block)
        self
      end
  
  
      def inspect #:nodoc:
        "<Sunspot::Search:#{query.to_params.inspect}>"
      end

      def add_field_group(field) #:nodoc:
        add_group(field.name, FieldGroup.new(field, self))
      end
  
      def add_field_facet(field, options = {}) #:nodoc:
        name = (options[:name] || field.name)
        add_facet(name, FieldFacet.new(field, self, options))
      end
  
      def add_query_facet(name, options) #:nodoc:
        add_facet(name, QueryFacet.new(name, self, options))
      end
  
      def add_date_facet(field, options) #:nodoc:
        name = (options[:name] || field.name)
        add_facet(name, DateFacet.new(field, self, options))
      end

      def add_range_facet(field, options) #:nodoc:
        name = (options[:name] || field.name)
        add_facet(name, RangeFacet.new(field, self, options))
      end

      def highlights_for(doc) #:nodoc:
        if @solr_result['highlighting']
          @solr_result['highlighting'][doc['id']]
        end
      end
  
      private
  
      def dsl
        raise NotImplementedError 
      end
  
      def execute_request(params)
        raise NotImplementedError
      end
  
      def solr_response
        @solr_response ||= @solr_result['response'] || {}
      end
  
      def solr_response_header
        @solr_response_header ||= @solr_result['responseHeader'] || {}
      end

      def solr_docs
        solr_response['docs']
      end
  
      def verified_hits
        @verified_hits ||= paginate_collection(super)
      end
  
      def paginate_collection(collection)
        PaginatedCollection.new(collection, @query.page, @query.per_page, total)
      end
  
      def add_facet(name, facet)
        @facets << facet
        @facets_by_name[name.to_sym] = facet
      end

      def add_group(name, group)
        @groups << group
        @groups_by_name[name.to_sym] = group
      end
      
      # Clear out all the cached ivars so the search can be called again.
      def reset
        @results = @hits = @verified_hits = @total = @solr_response = @doc_ids = nil
      end
    end
  end
end
