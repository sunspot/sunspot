module Sunspot
  # 
  # This class encapsulates a query that is to be sent to Solr. The query is
  # constructed in the block passed to the Sunspot.search method, using the
  # Sunspot::DSL::Query interface. Instances of Query, as well as all of the
  # components it contains, respond to the #to_params method, which returns
  # a hash of parameters in the format recognized by the solr-ruby API.
  #
  class Query #:nodoc:
    attr_writer :keywords # <String> full-text keyword boolean phrase

    def initialize(types, configuration) #:nodoc:
      @types, @configuration = types, configuration
      @rows = @configuration.pagination.default_per_page
    end

    # 
    # Representation of this query as solr-ruby parameters. Constructs the hash
    # by deep-merging scope and facet parameters, adding in various other
    # parameters from instance data.
    #
    # Note that solr-ruby takes the :q parameter as a separate argument; for
    # the sake of consistency, the Query object ignores this fact (the Search
    # object extracts it back out).
    #
    # ==== Returns
    #
    # Hash:: Representation of query in solr-ruby form
    #
    def to_params
      params = {}
      query_components = []
      query_components << @keywords if @keywords
      query_components << types_phrase if types_phrase
      params[:q] = query_components.map { |component| "(#{component})"} * ' AND '
      params[:sort] = @sort if @sort
      params[:start] = @start if @start
      params[:rows] = @rows if @rows
      for component in components
        Util.deep_merge!(params, component.to_params)
      end
      params
    end

    # 
    # Add a query component
    #
    # ==== Parameters
    #
    # component<~to_params>::  A restriction query component
    #
    def add_component(component)
      components << component
    end

    # 
    # Add instance of Sunspot::Restriction::Base to query components. This
    # method is exposed to the DSL because the Query instance holds field
    # definitions and is able to translate field names into full field
    # definitions, and memoize # the result.
    # 
    # ==== Parameters
    #
    # field_name<Symbol>:: Name of the field to which the restriction applies
    # restriction_clazz<Class>::
    #   Subclass of Sunspot::Restriction::Base to instantiate
    # value<Object>::
    #   Value against which the restriction applies (e.g. less_than(2) has a
    #   value of 2)
    # negative:: Whether this restriction should be negated
    #
    # ==== Returns
    #
    # Sunspot::Restriction::Base:: Restriction instance
    #
    def add_restriction(field_name, restriction_clazz, value, negative = false)
      add_component(restriction_clazz.new(field(field_name), value, negative))
    end

    # 
    # Add a field facet
    #
    # ==== Parameters
    #
    # field_name<Symbol>:: Name of the field on which to get a facet
    #
    def add_field_facet(field_name)
      add_component(Facets::FieldFacet.new(field(field_name)))
    end

    #
    # Sets @start and @rows instance variables using pagination semantics
    #
    # ==== Parameters
    #
    # page<Integer>:: Page on which to start
    # per_page<Integer>::
    #   How many rows to display per page. Default taken from
    #   Sunspot.config.pagination.default_per_page
    #
    def paginate(page, per_page = nil)
      per_page ||= @configuration.pagination.default_per_page
      @start = (page - 1) * per_page
      @rows = per_page
    end

    # 
    # Set result ordering.
    #
    # ==== Parameters
    #
    # field_name<Symbol>:: Name of the field on which to order
    # direction<Symbol>:: :asc or :desc (default :asc)
    #
    def order_by(field_name, direction = nil)
      direction ||= :asc
      (@sort ||= []) << { field(field_name).indexed_name.to_sym => (direction.to_s == 'asc' ? :ascending : :descending) }
    end

    # 
    # Page that this query will return (used by Sunspot::Search to expose
    # pagination)
    #
    # ==== Returns
    #
    # Integer:: Page number
    #
    def page
      if @start && @rows
        @start / @rows + 1
      else
        1
      end
    end

    #
    # Number of rows per page that this query will return (used by
    # Sunspot::Search to expose pagination)
    #
    # ==== Returns
    #
    # Integer:: Rows per page
    #
    def per_page
      @rows
    end

    # 
    # Get a DSL instance for building this query.
    #
    # ==== Returns
    #
    # Sunspot::DSL::Query:: DSL instance
    #
    def dsl
      @dsl ||= DSL::Query.new(self)
    end

    # 
    # Build the query using the DSL block passed into Sunspot.search
    #
    # ==== Returns
    #
    # Sunspot::Query:: self
    #
    def build(&block)
      dsl.instance_eval(&block)
      self
    end

    # 
    # Get a Sunspot::Field::Base instance corresponding to the given field name
    #
    # ==== Parameters
    #
    # field_name<Symbol>:: The field name for which to find a field
    #
    # ==== Returns
    #
    # Sunspot::Field::Base:: The field object corresponding to the given name
    #
    # ==== Raises
    #
    # ArgumentError::
    #   If the given field name is not configured for the types being queried
    #
    def field(field_name)
      fields_hash[field_name.to_sym] || raise(UnrecognizedFieldError, "No field configured for #{@types * ', '} with name '#{field_name}'")
    end

    #TODO document
    def options=(options) #:nodoc:
      if options.has_key?(:keywords)
        self.keywords = options[:keywords]
      end
      if options.has_key?(:conditions)
        options[:conditions].each_pair do |field_name, value|
          begin
            restriction_type =
              case value
              when Array
                Restriction::AnyOf
              when Range
                Restriction::Between
              else
                Restriction::EqualTo
              end
            add_restriction(field_name, restriction_type, value)
          rescue UnrecognizedFieldError
            # ignore fields we don't recognize
          end
        end
      end
      if options.has_key?(:order)
        for order in Array(options[:order])
          order_by(*order.split(' '))
        end
      end
      if options.has_key?(:page)
        paginate(options[:page], options[:per_page])
      end
    end

    private

    # ==== Returns
    #
    # Array:: Collection of query components
    #
    def components
      @components ||= []
    end

    # 
    # Boolean phrase that restricts results to objects of the type(s) under
    # query. If this is an open query (no types specified) then it sends a
    # no-op phrase because Solr requires that the :q parameter not be empty.
    #
    # TODO don't send a noop if we have a keyword phrase
    # TODO this should be sent as a filter query when possible, especially
    #      if there is a single type, so that Solr can cache it
    #
    # ==== Returns
    #
    # String:: Boolean phrase for type restriction
    #
    def types_phrase
      if @types.nil? || @types.empty? then "type:[* TO *]"
      elsif @types.length == 1 then "type:#{@types.first}"
      else "type:(#{@types * ' OR '})"
      end
    end

    # 
    # Return a hash of field names to field objects, containing all fields
    # that are common to all of the classes under search. In order for fields
    # to be common, they must be of the same type and have the same
    # value for allow_multiple?. This method is memoized.
    #
    # ==== Returns
    #
    # Hash:: field names keyed to field objects
    #
    def fields_hash
      @fields_hash ||= begin
        fields_hash = @types.inject({}) do |hash, type|
          Setup.for(type).fields.each do |field|
            (hash[field.name.to_sym] ||= {})[type.name] = field
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
