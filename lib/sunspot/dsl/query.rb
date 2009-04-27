module Sunspot
  module DSL
    # This class presents a DSL for constructing queries using the
    # Sunspot.search method. Methods of this class are available inside the
    # search block.
    #
    # See Sunspot.search for usage examples
    #
    class Query
      def initialize(query) #:nodoc:
        @query = query
      end

      # Specify a phrase that should be searched as fulltext. Only +text+
      # fields are searched - see DSL::Fields.text
      #
      # Note that the keywords are passed directly to Solr unadulterated. The
      # advantage of this is that users can potentially use boolean logic to
      # make advanced searches. The disadvantage is that syntax errors are
      # possible. This may get better in a future version; suggestions are
      # welcome.
      #
      # ==== Parameters
      #
      # keywords<String>:: phrase to perform fulltext search on
      #
      def keywords(keywords)
        @query.keywords = keywords
      end

      # TODO document after refactor
      def with
        @conditions_builder ||= DSL::Scope::implementation(@query.field_names).new(@query)
      end

      # TODO document after refactor
      def without(*instances)
        if instances.empty?
          @negative_conditions_builder ||= DSL::Scope::implementation(@query.field_names).new(@query, true)
        else
          for instance in instances.flatten
            @query.add_component(Restriction::SameAs.new(instance, true))
          end
        end
      end

      # Paginate your search. This works the same way as WillPaginate's
      # paginate().
      #
      # Note that Solr searches are _always_ paginated. Not calling #paginate is
      # the equivalent of calling:
      #
      #   paginate(:page => 1, :per_page => Sunspot.config.pagination.default_per_page)
      #
      # ==== Options (options)
      #
      # :page<Integer>:: The requested page (required)
      #
      # :per_page<Integer>::
      #   How many results to return per page. The default is the value in
      #   +Sunspot.config.pagination.default_per_page+
      #
      def paginate(options = {})
        page = options.delete(:page) || raise(ArgumentError, "paginate requires a :page argument")
        per_page = options.delete(:per_page)
        raise ArgumentError, "unknown argument #{options.keys.first.inspect} passed to paginate" unless options.empty?
        @query.paginate(page, per_page)
      end

      # Specify the order that results should be returned in. At this point only
      # one field can be used for ordering, but that will surely change in 
      # future versions
      #
      # ==== Parameters
      #
      # field_name<Symbol>:: the field to use for ordering
      # direction<Symbol>:: :asc or :desc (default :asc)
      #
      def order_by(field_name, direction = nil)
        @query.order_by(field_name, direction)
      end

      # Request facets on the given field names. See Sunspot::Search#facet and
      # Sunspot::Facet for information on what is returned.
      #
      # ==== Parameters
      #
      # field_names...<Symbol>:: fields for which to return field facets
      def facet(*field_names)
        for field_name in field_names
          @query.add_field_facet(field_name)
        end
      end
    end
  end
end
