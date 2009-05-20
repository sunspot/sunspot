module Sunspot
  #TODO document
  class DynamicQuery
    def initialize(dynamic_field, query)
      @dynamic_field, @query = dynamic_field, query
    end

    def add_restriction(field_name, restriction_type, value, negated = false)
      if restriction_type.is_a?(Symbol)
        restriction_type = Restriction[restriction_type]
      end
      @query.add_component(restriction_type.new(@dynamic_field.build(field_name), value, negated))
    end

    def add_field_facet(field_name)
      @query.add_component(Facets::FieldFacet.new(@dynamic_field.build(field_name)))
    end

    def order_by(field_name, direction)
      @query.sort << { @dynamic_field.build(field_name).indexed_name.to_sym => (direction.to_s == 'asc' ? :ascending : :descending) }
    end
  end
end
