module Sunspot
  # 
  # The CompositeSetup class encapsulates a collection of setups, and responds
  # to a subset of the methods that Setup responds to (in particular, the
  # methods required to build queries).
  #
  class CompositeSetup #:nodoc:
    class << self
      alias_method :for, :new
    end

    def initialize(types)
      @types = types
    end

    # 
    # Collection of Setup objects for the enclosed types
    #
    # ==== Returns
    #
    # Array:: Collection of Setup objects
    #
    def setups
      @setups ||= @types.map { |type| Setup.for(type) }
    end

    # 
    # Return the names of the encapsulated types
    #
    # ==== Returns
    #
    # Array:: Collection of class names
    #
    def type_names
      @type_names ||= @types.map { |clazz| clazz.name }
    end

    # 
    # Get a text field object by its public name. A field will be returned if
    # it is configured for any of the enclosed types.
    #
    # ==== Returns
    #
    # Sunspot::FulltextField:: Text field with the given public name
    #
    # ==== Raises
    #
    # UnrecognizedFieldError::
    #   If no field with that name is configured for any of the enclosed types.
    #
    def text_fields(field_name)
      if text_fields = text_fields_hash[field_name.to_sym]
        text_fields.to_a
      else
        raise(
          UnrecognizedFieldError,
          "No text field configured for #{@types * ', '} with name '#{field_name}'"
        )
      end
    end

    # 
    # Get a Sunspot::AttributeField instance corresponding to the given field name
    #
    # ==== Parameters
    #
    # field_name<Symbol>:: The public field name for which to find a field
    #
    # ==== Returns
    #
    # Sunspot::AttributeField The field object corresponding to the given name
    #
    # ==== Raises
    #
    # ArgumentError::
    #   If the given field name is not configured for the types being queried
    #
    def field(field_name) #:nodoc:
      fields_hash[field_name.to_sym] || raise(
        UnrecognizedFieldError,
        "No field configured for #{@types * ', '} with name '#{field_name}'"
      )
    end

    # 
    # Get a dynamic field factory for the given base name.
    #
    # ==== Returns
    #
    # DynamicFieldFactory:: Factory for dynamic fields with the given base name
    #
    # ==== Raises
    #
    # UnrecognizedFieldError::
    #   If the given base name is not configured as a dynamic field for the types being queried
    #
    def dynamic_field_factory(field_name)
      dynamic_field_factories_hash[field_name.to_sym] || raise(
        UnrecognizedFieldError,
        "No dynamic field configured for #{@types * ', '} with name #{field_name.inspect}"
      )
    end

    # 
    # Collection of all text fields configured for any of the enclosed types.
    #
    # === Returns
    #
    # Array:: Text fields configured for the enclosed types
    #
    def all_text_fields
      @text_fields ||= text_fields_hash.values.map { |set| set.to_a }.flatten
    end

    def all_more_like_this_fields
      @more_like_this_fields ||= more_like_this_fields_hash.values.map { |set| set.to_a }.flatten
    end

    private

    # 
    # Return a hash of field names to text field objects, containing all fields
    # that are configured for any of the types enclosed.
    #
    # ==== Returns
    #
    # Hash:: Hash of field names to text field objects.
    #
    def text_fields_hash
      @text_fields_hash ||=
        setups.inject({}) do |hash, setup|
          setup.all_text_fields.each do |text_field|
            (hash[text_field.name] ||= Set.new) << text_field
          end
          hash
        end
    end

    def more_like_this_fields_hash
      @more_like_this_fields_hash ||=
        setups.inject({}) do |hash, setup|
          setup.all_more_like_this_fields.each do |more_like_this_field|
            (hash[more_like_this_field.name] ||= Set.new) << more_like_this_field
          end
          hash
        end
    end

    # 
    # Return a hash of field names to field objects, containing all fields
    # that are common to all of the classes enclosed. In order for fields
    # to be common, they must be of the same type and have the same
    # value for allow_multiple? and stored?. This method is memoized.
    #
    # ==== Returns
    #
    # Hash:: field names keyed to field objects
    #
    def fields_hash
      @fields_hash ||=
        begin
          field_sets_hash = Hash.new { |h, k| h[k] = Set.new }
          @types.each do |type|
            Setup.for(type).fields.each do |field|
              field_sets_hash[field.name.to_sym] << field
            end
          end
          fields_hash = {}
          field_sets_hash.each_pair do |field_name, set|
            if set.length == 1
              fields_hash[field_name] = set.to_a.first
            end
          end
          fields_hash
        end
    end

    # 
    # Return a hash of dynamic field base names to dynamic field factories for
    # those base names. Criteria for the inclusion are the same as for
    # #fields_hash()
    #
    def dynamic_field_factories_hash
      @dynamic_field_factories_hash ||=
        begin
          dynamic_field_factories_hash = @types.inject({}) do |hash, type|
            Setup.for(type).dynamic_field_factories.each do |field_factory|
              (hash[field_factory.name.to_sym] ||= {})[type.name] = field_factory
            end
            hash
          end
          dynamic_field_factories_hash.each_pair do |field_name, field_configurations_hash|
            if @types.any? { |type| field_configurations_hash[type.name].nil? }
              dynamic_field_factories_hash.delete(field_name)
            else
              dynamic_field_factories_hash[field_name] = field_configurations_hash.values.first
            end
          end
        end
    end
  end
end
