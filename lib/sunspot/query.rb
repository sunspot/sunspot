module Sunspot
  class Query
    attr_accessor :keywords, :conditions, :rows, :start, :sort

    def initialize(types, params, configuration)
      @types, @configuration = types, configuration
      paginate
    end

    def to_solr
      query_components = []
      query_components << keywords if keywords
      query_components << types_query if types_query
      query_components.map { |component| "(#{component})"} * ' AND '
    end

    def scope_queries
      scope.map { |condition| condition.to_solr_query } +
        negative_scope.map { |condition| condition.to_negative_solr_query }
    end

    def add_scope(condition)
      scope << condition
    end

    def add_negative_scope(condition)
      negative_scope << condition
    end

    def build_condition(field_name, condition_clazz, value)
      condition_clazz.new(field(field_name), value)
    end

    def paginate(page = nil, per_page = nil)
      page ||= 1
      per_page ||= @configuration.pagination.default_per_page
      @start = (page - 1) * per_page
      @rows = per_page
    end

    def order_by(field_name, direction = nil)
      direction ||= :asc
      @sort = [{ field(field_name).indexed_name.to_sym => (direction.to_s == 'asc' ? :ascending : :descending) }] #TODO should support multiple order columns
    end

    def page
      return nil unless start && rows
      start / rows + 1
    end

    def dsl
      @dsl ||= ::Sunspot::DSL::Query.new(self)
    end

    def build_with(builder_class, *args)
      builder_class.new(dsl, @types, fields_hash.keys, *args)
    end

    def field_names
      fields_hash.keys
    end

    def fields
      fields_hash.values
    end

    alias_method :per_page, :rows

    private

    def scope
      @scope ||= []
    end

    def negative_scope
      @negative_scope ||= []
    end

    def types_query
      if @types.nil? || @types.empty? then "type:[* TO *]"
      elsif @types.length == 1 then "type:#{@types.first}"
      else "type:(#{@types * ' OR '})"
      end
    end

    def field(field_name)
      fields_hash[field_name.to_s] || raise(ArgumentError, "No field configured for #{@types * ', '} with name '#{field_name}'")
    end

    def fields_hash
      @fields_hash ||= begin
        fields_hash = @types.inject({}) do |hash, type|
          Sunspot::Setup.for(type).fields.each do |field|
            (hash[field.name.to_s] ||= {})[type.name] = field
          end
          hash
        end
        fields_hash.each_pair do |field_name, field_configurations_hash|
          if @types.any? { |type| field_configurations_hash[type.name].nil? } # at least one type doesn't have this field configured
            fields_hash.delete(field_name)
          elsif field_configurations_hash.values.map { |configuration| configuration.indexed_name }.uniq.length != 1 # fields with this name have different configs
            fields_hash.delete(field_name)
          else
            fields_hash[field_name] = field_configurations_hash.values.first
          end
        end
      end
    end
  end
end
