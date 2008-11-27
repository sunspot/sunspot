module Sunspot
  class Conditions
    def initialize(query, conditions_hash)
      @query = query
      @conditions_hash = conditions_hash.inject({}) do |hash, pair|
        field_name, value = pair
        hash[field_name.to_s] = value
        hash
      end
    end
    
    def interpret(field_name, condition_type)
      operators_hash[field_name.to_s] = Sunspot::Restriction.const_get condition_type.to_s.camel_case
    end

    def default(field_name, value)
      conditions_hash[field_name.to_s] ||= value
    end

    def conditions
      conditions_hash.map { |field_name, value| condition_for(field_name, value) }.compact
    end

    protected
    attr_reader :conditions_hash

    def condition_for(field_name, value)
      operator = operator_for(field_name) || default_operator_for(value)
      begin
        @query.build_condition field_name, operator, value
      rescue ArgumentError
        nil # fail silently if field isn't configured
      end
    end

    def default_operator_for(value)
      if value.is_a?(Array) then Sunspot::Restriction::AnyOf
      else Sunspot::Restriction::EqualTo
      end
    end

    def operator_for(field_name)
      operators_hash[field_name.to_s] 
    end

    def operators_hash
      @operators_hash ||= {}
    end
  end
end
