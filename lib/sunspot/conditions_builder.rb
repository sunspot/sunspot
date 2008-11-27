module Sunspot
  class Conditions
    def initialize(query, conditions_hash)
      @query, @conditions_hash = query, conditions_hash
    end
    
    def interpret(field_name, condition_type)
      operators_hash[field_name.to_s] = Sunspot::Restriction.const_get condition_type.to_s.camel_case
    end

    def conditions
      conditions_hash.map { |field_name, value| condition_for(field_name, value) }
    end

    protected
    attr_reader :conditions_hash

    def condition_for(field_name, value)
      operator = operator_for(field_name) || default_operator_for(value)
      @query.build_condition field_name, operator, value
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
