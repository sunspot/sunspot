module Sunspot
  class Query
    attr_accessor :keywords, :conditions, :rows, :start, :sort

    def initialize(types, params, configuration)
      @keywords, @types, @configuration = params[:keywords], types, configuration
      @conditions = Sunspot::Conditions.new(self, params[:conditions] || {})
      paginate(params[:page], params[:per_page]) if params[:page]
      self.order = params[:order] if params[:order]
      attributes[:keywords] = @keywords
      params[:conditions].each_pair do |field_name, value|
        attributes[:conditions][field_name.to_sym] = value
      end if params[:conditions]
    end

    def to_solr
      query_components = []
      query_components << keywords if keywords
      query_components << types_query if types_query
      query_components.map { |component| "(#{component})"} * ' AND '
    end

    def filter_queries
      scope_queries + condition_queries
    end

    def add_scope(condition)
      scope << condition
    end

    def build_condition(field_name, condition_clazz, value)
      condition_clazz.new(field(field_name), value)
    end

    def paginate(page, per_page = nil)
      per_page ||= configuration.pagination.default_per_page
      @start = (page - 1) * per_page
      @rows = per_page
      attributes[:page], attributes[:per_page] = page, per_page
    end

    def order=(order)
      order_by(*order.split(' '))
    end

    def order_by(field_name, direction = nil)
      direction ||= :asc
      @sort = "#{field(field_name).indexed_name} #{direction}"
      attributes[:order] = "#{field_name} #{direction}"
    end

    def page
      return nil unless start && rows
      start / rows + 1
    end

    def attributes
      @attributes ||= {
        :order => nil,
        :conditions => fields_hash.keys.inject({}) { |conditions, key| conditions[key.to_sym] = nil; conditions }
      }
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

    def condition_queries
      conditions.restrictions.map { |condition| condition.to_solr_query }
    end

    def types_query
      if types.nil? || types.empty? then "type:[* TO *]"
      elsif types.length == 1 then "type:#{types.first}"
      else "type:(#{types * ' OR '})"
      end
    end

    def field(field_name)
      fields_hash[field_name.to_s] || raise(ArgumentError, "No field configured for #{types * ', '} with name '#{field_name}'")
    end

    def fields_hash
      @fields_hash ||= begin
        fields_hash = types.inject({}) do |hash, type|
          ::Sunspot::Field.for(type).each do |field|
            (hash[field.name.to_s] ||= {})[type.name] = field
          end
          hash
        end
        fields_hash.each_pair do |field_name, field_configurations_hash|
          if types.any? { |type| field_configurations_hash[type.name].nil? } # at least one type doesn't have this field configured
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
