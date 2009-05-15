module Sunspot
  #TODO document
  class DynamicQuery
    def initialize(dynamic_field, query)
      @dynamic_field, @query = dynamic_field, query
      @components = []
    end

    def add_restriction(field_name, restriction_type, value, negated = false)
      if restriction_type.is_a?(Symbol)
        restriction_type = Restriction[restriction_type]
      end
      @components << restriction_type.new(@dynamic_field.build(field_name, value), value, negated)
    end

    def to_params
      params = {}
      for component in @components
        Util.deep_merge!(params, component.to_params)
      end
      params
    end
  end
end
