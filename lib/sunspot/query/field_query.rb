module Sunspot
  module Query
    class FieldQuery < Scope
      # 
      # Add a field facet. See Sunspot::Facet for more information.
      #
      # ==== Parameters
      #
      # field_name<Symbol>:: Name of the field on which to get a facet
      #
      def add_field_facet(field_name, options = nil)
        add_component(FieldFacet.build(build_field(field_name), options || {}))
      end

      #TODO document
      def add_query_facet(name)
        add_component(facet = QueryFacet.new(name, setup))
        query_facets[name.to_sym] = facet
        facet
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
        add_sort(Sort.new(build_field(field_name), direction))
      end
    end
  end
end
