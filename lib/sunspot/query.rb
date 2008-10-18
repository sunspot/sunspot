module Sunspot
  class Query
    attr_accessor :keywords

    def initialize(types, keywords, conditions)
      @keywords, @conditions = keywords, conditions
      self.types = types
    end

    def to_solr
      query_components = []
      query_components << keywords if keywords
      query_components << types_query if types_query
      query_components.map { |component| "(#{component})"} * ' AND '
    end

    protected
    attr_accessor :conditions, :types

    private
    
    #TODO once the condition structure is up and running, this method
    #     can be ditched - just need it to make the spec pass now
    def types_query
      if types.nil? || types.empty? then nil
      elsif types.length == 1 then "type:#{types.first}"
      else "type:(#{types * ' OR '})"
      end
    end

    def types=(types)
      @types = types
      fields_hash = {}
      types.each do |type|
        ::Sunspot::Field.for(type).each do |field|
          if fields_hash.has_key? field.name && fields_hash[field.name] != field
            raise "Incompatible field definitions for #{field.name}"
          else
            fields_hash[field.name] ||= field
          end
        end
      end
    end
  end
end
