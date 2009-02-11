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

    def filter_queries
      scope_queries
    end

    def add_scope(condition)
      scope << condition
    end

    def build_condition(field_name, condition_clazz, value)
      condition_clazz.new(field(field_name), value)
    end

    def paginate(page = nil, per_page = nil)
      page ||= 1
      per_page ||= configuration.pagination.default_per_page
      @start = (page - 1) * per_page
      @rows = per_page
    end

    def order=(order)
      order_by(*order.split(' '))
    end

    def order_by(field_name, direction = nil)
      solr_direction = direction.to_s == 'desc' ? :descending : :ascending
      #TODO should support multiple order columns
      @sort = [{ field(field_name).indexed_name.to_sym => solr_direction }]
    end

    def page
      return nil unless start && rows
      start / rows + 1
    end

    def dsl
      @dsl ||= ::Sunspot::DSL::Query.new(self)
    end

    def build_with(builder_class, *args)
      builder_class.new(dsl, types, fields_hash.keys, *args)
    end

    alias_method :per_page, :rows

    protected
    attr_accessor :types, :configuration

    private

    def scope
      @scope ||= []
    end

    def scope_queries
      scope.map { |condition| condition.to_solr_query }
    end

    def types_query
      if types.nil? || types.empty? then "type:[* TO *]"
      elsif types.length == 1 then "type:#{types.first}"
      else "type:(#{types * ' OR '})"
      end
    end

    def field(field_name)
      fields_hash[field_name.to_s] ||
        raise(ArgumentError,
              "No field configured for #{types * ', '} " +
              "with name '#{field_name}'")
    end

    def fields_hash
      @fields_hash ||= begin
        fields_for_types = Hash.new { |h, k| h[k] = {} }
        types.each do |type|
          ::Sunspot::Field.for(type).each do |field|
            fields_for_types[field.name.to_s][type.name] = field
          end
        end
        fields_hash = {}
        fields_for_types.each_pair do |field_name, fields_for_type|
          unless types.any? { |type|
              fields_for_type[type.name].nil? } ||
            fields_for_type.values.map { |configuration|
              configuration.indexed_name }.uniq.length != 1 then
            fields_hash[field_name] = fields_for_type.values.first
          end
        end
        fields_hash
      end
    end
  end
end
