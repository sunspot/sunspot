%w(base_query scope field_query connective dynamic_query field_facet pagination restriction sort sort_composite).each do |file|
  require File.join(File.dirname(__FILE__), 'query', file)
end

module Sunspot
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
  module Query
    class Query < FieldQuery
      def initialize(setup, configuration) #:nodoc:
        @setup, @configuration = setup, configuration
        @components = []
        @components << @base_query = BaseQuery.new(setup)
        @components << @pagination = Pagination.new(@configuration)
        @components << @sort = SortComposite.new
      end

      def keywords=(keywords)
        set_keywords(keywords)
      end

      def set_keywords(keywords, options = {})
        @base_query.keywords = keywords
        @base_query.keyword_options = options
      end

      # 
      # Add a component to the query. Used by objects that proxy to the query
      # object.
      # 
      # ==== Parameters
      # 
      # component<~to_params>:: Query component to add.
      # 
      def add_component(component) #:nodoc:
        @components << component
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
      def paginate(page, per_page = nil)
        @pagination.page, @pagination.per_page = page, per_page
      end

      def order_by_random
        add_sort(Sort.new(RandomField.new))
      end

      # 
      # Build the query using the DSL block passed into Sunspot.search
      #
      # ==== Returns
      #
      # Sunspot::Query:: self
      #
      def build(&block)
        Util.instance_eval_or_call(dsl, &block)
        self
      end

      # 
      # Representation of this query as solr-ruby parameters. Constructs the hash
      # by deep-merging scope and facet parameters, adding in various other
      # parameters from instance data.
      #
      # Note that solr-ruby takes the :q parameter as a separate argument; for
      # the sake of consistency, the Query object ignores this fact (the Search
      # object extracts it back out).
      #
      # ==== Returns
      #
      # Hash:: Representation of query in solr-ruby form
      #
      def to_params #:nodoc:
        params = {}
        query_components = []
        for component in @components
          Util.deep_merge!(params, component.to_params)
        end
        params
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
      # Get a DSL instance for building this query.
      #
      # ==== Returns
      #
      # Sunspot::DSL::Query:: DSL instance
      #
      def dsl #:nodoc:
        @dsl ||= DSL::Query.new(self)
      end

      #TODO document
      def add_sort(sort) #:nodoc:
        @sort << sort
      end

      # 
      # Pass in search options as a hash. This is not the preferred way of
      # building a Sunspot search, but it is made available as experience shows
      # Ruby developers like to pass in hashes. Probably nice for quick one-offs
      # on the console, anyway.
      #
      # ==== Options (+options+)
      #
      # :keywords:: Keyword string for fulltext search
      # :conditions::
      #   Hash of key-value pairs, where keys are field names, and values are one
      #   of scalar, Array, or Range. Scalars are evaluated as EqualTo
      #   restrictions; Arrays are AnyOf restrictions, and Ranges are Between
      #   restrictions.
      # :order::
      #   Order the search results. Either a string or array of strings of the
      #   form "field_name direction"
      # :page::
      #   Page to use for pagination
      # :per_page::
      #   Number of results to show per page
      #
      def options=(options) #:nodoc:
        if options.has_key?(:keywords)
          self.keywords = options[:keywords]
        end
        if options.has_key?(:conditions)
          options[:conditions].each_pair do |field_name, value|
            begin
              restriction_type =
                case value
                when Array
                  Restriction::AnyOf
                when Range
                  Restriction::Between
                else
                  Restriction::EqualTo
                end
              add_restriction(field_name, restriction_type, value)
            rescue UnrecognizedFieldError
              # ignore fields we don't recognize
            end
          end
        end
        if options.has_key?(:order)
          for order in Array(options[:order])
            order_by(*order.split(' '))
          end
        end
        if options.has_key?(:page)
          paginate(options[:page], options[:per_page])
        end
      end
    end
  end
end
