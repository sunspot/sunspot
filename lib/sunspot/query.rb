module Sunspot
  class Query
    attr_accessor :keywords

    def initialize(types, keywords, conditions)
      @keywords, @types = keywords, types
      @conditions = conditions
    end

    def to_solr
      query_components = []
      query_components << keywords if keywords
      query_components.concat scope_queries
      query_components.concat condition_queries
      query_components << types_query if types_query
      query_components.map { |component| "(#{component})"} * ' AND '
    end

    def add_scope(condition)
      scope << condition
    end

    def build_condition(field_name, condition_clazz, value)
      field = fields_hash[field_name.to_s] || raise(ArgumentError, "No field configured for #{types * ', '} with name '#{field_name}'")
      condition_clazz.new(field, value)
    end

    def interpret_condition(field_name, condition_clazz)
      hash_interpreters[field_name.to_s] = condition_clazz
    end

    protected
    attr_accessor :types

    private

    def conditions
      conditions = @conditions.map do |field_name, value|
        condition_clazz = if hash_interpreters.has_key?(field_name.to_s) then hash_interpreters[field_name.to_s]
                          elsif value.is_a?(Array) then ::Sunspot::Condition::AnyOf
                          else ::Sunspot::Condition::EqualTo
                          end
        begin
          build_condition field_name, condition_clazz, value
        rescue ArgumentError #TODO make our own exception class for this
          # ignore nonexistant fields
        end
      end
      conditions.compact!
      conditions
    end

    def scope
      @scope ||= []
    end

    def scope_queries
      scope.map { |condition| condition.to_solr_query }
    end

    def condition_queries
      conditions.map { |condition| condition.to_solr_query }
    end

    def hash_interpreters
      @hash_interpreters ||= {}
    end

    #TODO once the condition structure is up and running, this method
    #     can be ditched - just need it to make the spec pass now
    def types_query
      if types.nil? || types.empty? then nil
      elsif types.length == 1 then "type:#{types.first}"
      else "type:(#{types * ' OR '})"
      end
    end

    def fields_hash
      @fields_hash ||= types.inject({}) do |hash, type|
        ::Sunspot::Field.for(type).each do |field|
          hash[field.name.to_s] ||= field
        end
        hash
      end
    end
  end
end
