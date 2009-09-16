%w(base_query fulltext_base_query scope field_query connective dynamic_query
   field_facet query_facet query_facet_row query_field_facet boost_query local
   pagination restriction sort sort_composite text_field_boost
   highlighting).each do |file|
  require File.join(File.dirname(__FILE__), 'query', file)
end

module Sunspot
  module Query #:nodoc:
    # 
    # This class encapsulates a query that is to be sent to Solr. The query is
    # constructed in the block passed to the Sunspot.search method, using the
    # Sunspot::DSL::Query interface. It can also be accessed directly by calling
    # #query on a Search object (presumably a not-yet-run one created using
    # Sunspot#new_search), which might be more suitable than the DSL when an
    # intermediate object has responsibility for building the query dynamically.
    #--
    # Instances of Query, as well as all of the components it contains, respond to
    # the #to_params method, which returns a hash of parameters in the format
    # recognized by the solr-ruby API.
    #
    class Query < FieldQuery #:nodoc:
      attr_reader :query_facets #:nodoc:

      def initialize(types, setup, configuration) #:nodoc:
        super(setup)
        @query_facets = {}
        @components[0] = @base_query = BaseQuery.new(types, setup)
        @components << @pagination = Pagination.new(configuration)
        @components << @sort = SortComposite.new
      end

      #
      # Sets @start and @rows instance variables using pagination semantics
      #
      # ==== Parameters
      #
      # page<Integer>:: Page on which to start
      # per_page<Integer>::
      #   How many rows to display per page. Default taken from
      #   Sunspot.config.pagination.default_per_page
      #
      def paginate(page, per_page = nil) #:nodoc:
        @pagination.page, @pagination.per_page = page, per_page
      end

      def add_location_restriction(coordinates, miles) #:nodoc:
        @components << Local.new(coordinates, miles)
      end

      def add_text_fields_scope
        @components << scope = Scope.new(TextFieldSetup.new(@setup))
        scope
      end

      # 
      # Page that this query will return (used by Sunspot::Search to expose
      # pagination)
      #
      # ==== Returns
      #
      # Integer:: Page number
      #
      def page #:nodoc:
        @pagination.page
      end

      #
      # Number of rows per page that this query will return (used by
      # Sunspot::Search to expose pagination)
      #
      # ==== Returns
      #
      # Integer:: Rows per page
      #
      def per_page #:nodoc:
        @pagination.per_page
      end

      # 
      # Get the query facet with the given name. Used by the Search object to
      # match query facet results with the requested query facets.
      #
      def query_facet(name) #:nodoc:
        @query_facets[name.to_sym]
      end

      # 
      # Add a Sort object into this query's sort composite.
      #
      def add_sort(sort) #:nodoc:
        @sort << sort
      end

      # 
      # Set the keywords for this query, along with keyword options. See
      # Query::FulltextBaseQuery for information on what the options do. Returns
      # a FulltextBaseQuery object.
      #
      def set_keywords(keywords, options = {}) #:nodoc:
        if keywords.to_s =~ /\S/
          @components[0] = @base_query =
            FulltextBaseQuery.new(keywords, options, @base_query.types, @setup)
        end
      end
    end
  end
end
