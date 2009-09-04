module Sunspot
  module Query
    # 
    # This class acts as a base class for query components that encapsulate
    # operations on fields. It is subclassed by the Query::Query class and the
    # Query::DynamicQuery class.
    #
    class FieldQuery < Scope #:nodoc:
      # 
      # Add a field facet. See Sunspot::Facet for more information.
      #
      # ==== Parameters
      #
      # field_name<Symbol>:: Name of the field on which to get a facet
      #
      # ==== Returns
      #
      # FieldFacet:: The field facet object
      #
      def add_field_facet(field_name, options = nil)
        options ||= {}
        facet =
          if only = options.delete(:only)
            query_facets[field_name.to_sym] = QueryFieldFacet.new(@setup.field(field_name), only, options) 
          else
            FieldFacet.build(build_field(field_name), options)
          end
        add_component(facet)
      end

      # 
      # Add a query facet.
      #
      # ==== Parameters
      #
      # name<Symbol>::
      #   The name associated with the query facet. This is not passed to Solr,
      #   but allows the user to retrieve the facet result by passing the name
      #   to the Search#facet method.
      #
      # ==== Returns
      #
      # QueryFacet:: The query facet object
      #
      def add_query_facet(name, options)
        add_component(facet = QueryFacet.new(name, options, @setup))
        query_facets[name.to_sym] = facet
      end

      # 
      # Set result ordering.
      #
      # ==== Parameters
      #
      # field_name<Symbol>:: Name of the field on which to order
      # direction<Symbol>:: :asc or :desc (default :asc)
      #
      def order_by(field_name, direction = nil)
        sort =
          if special = Sort.special(field_name)
            special.new(direction)
          else
            Sort::FieldSort.new(build_field(field_name), direction)
          end
        add_sort(sort)
      end
    end
  end
end
