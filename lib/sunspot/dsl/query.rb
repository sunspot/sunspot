module Sunspot
  module DSL
    #
    # This class presents a DSL for constructing queries using the
    # Sunspot.search method. Methods of this class are available inside the
    # search block.
    #
    # See Sunspot.search for usage examples
    #
    class Query
      NONE = Object.new

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

      # 
      # Build a positive restriction. With one argument, this method returns
      # another DSL object which presents methods for attaching various
      # restriction types. With two arguments, acts as a shorthand for creating
      # an equality restriction.
      #
      # ==== Parameters
      #
      # field_name<Symbol>:: Name of the field on which to place the restriction
      # value<Symbol>::
      #   If passed, creates an equality restriction with this value
      #
      # ==== Returns
      #
      # Sunspot::DSL::Restriction::
      #   Restriction DSL object (if only one argument is passed)
      #
      # ==== Examples
      #
      # An equality restriction:
      #
      #   Sunspot.search do
      #     with(:blog_id, 1)
      #   end
      # 
      # Other restriction types:
      #
      #   Sunspot.search(Post) do
      #     with(:average_rating).greater_than(3.0)
      #   end
      #
      def with(field_name, value = NONE)
        if value == NONE
          DSL::Restriction.new(field_name.to_sym, @query, false)
        else
          @query.add_restriction(field_name, Sunspot::Restriction::EqualTo, value, false)
        end
      end

      # 
      # Build a negative restriction (exclusion). This method can take three
      # forms: equality exclusion, exclusion by another restriction, or identity
      # exclusion. The first two forms work the same way as the #with method;
      # the third excludes a specific instance from the search results.
      #
      # ==== Parameters (exclusion by field value)
      #
      # field_name<Symbol>:: Name of the field on which to place the exclusion
      # value<Symbol>::
      #   If passed, creates an equality exclusion with this value
      #
      # ==== Parameters (exclusion by identity)
      #
      # args<Object>...::
      #   One or more instances that should be excluded from the results
      #
      # ==== Examples
      #
      # An equality exclusion:
      #
      #   Sunspot.search(Post) do
      #     without(:blog_id, 1)
      #   end
      # 
      # Other restriction types:
      #
      #   Sunspot.search(Post) do
      #     without(:average_rating).greater_than(3.0)
      #   end
      #
      # Exclusion by identity:
      #
      #   Sunspot.search(Post) do
      #     without(some_post_instance)
      #   end
      #
      def without(*args)
        case args.first
        when String, Symbol
          field_name = args[0]
          value = args.length > 1 ? args[1] : NONE
          if value == NONE
            DSL::Restriction.new(field_name.to_sym, @query, true)
          else
            @query.add_restriction(field_name, Sunspot::Restriction::EqualTo, value, true)
          end
        else
          instances = args
          for instance in instances.flatten
            @query.add_component(Sunspot::Restriction::SameAs.new(instance, true))
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

      # Specify the order that results should be returned in. This method can
      # be called multiple times; precedence will be in the order given.
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
