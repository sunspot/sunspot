module Sunspot
  class Query
    attr_accessor :keywords, :conditions, :rows, :start, :sort

    def initialize(types, params) 
      @keywords, @types = params[:keywords], types
      @conditions = Sunspot::Conditions.new(self, params[:conditions] || {})
      paginate(params[:page], params[:per_page]) if params[:page]
      self.order = params[:order] if params[:order]
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
      per_page ||= 30 #FIXME this should come out of configuration
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
        :order => nil
      }
    end

    alias_method :per_page, :rows

    protected
    attr_accessor :types

    private

    def scope
      @scope ||= []
    end

    def scope_queries
      scope.map { |condition| condition.to_solr_query }
    end

    def condition_queries
      conditions.conditions.map { |condition| condition.to_solr_query } # TODO the fact that we're calling conditions.conditions means there is a semantics problem here somewhere
    end

    #TODO once the scope structure is up and running, this method
    #     can be ditched - just need it to make the spec pass now
    def types_query
      if types.nil? || types.empty? then nil
      elsif types.length == 1 then "type:#{types.first}"
      else "type:(#{types * ' OR '})"
      end
    end

    def field(field_name)
      fields_hash[field_name.to_s] || raise(ArgumentError, "No field configured for #{types * ', '} with name '#{field_name}'")
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
