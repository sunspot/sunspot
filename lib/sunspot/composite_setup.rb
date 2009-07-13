module Sunspot
  class CompositeSetup
    class << self
      alias_method :for, :new
    end

    def initialize(types)
      @types = types
    end

    def setups
      @setups ||= @types.map { |type| Setup.for(type) }
    end

    def type_names
      @type_names ||= @types.map { |clazz| clazz.name }
    end

    def text_field(name)
      text_fields_hash[field_name.to_sym] || raise(
        UnrecognizedFieldError,
        "No text field configured for #{@types * ', '} with name '#{field_name}'"
      )
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
    def field(field_name) #:nodoc:
      fields_hash[field_name.to_sym] || raise(
        UnrecognizedFieldError,
        "No field configured for #{@types * ', '} with name '#{field_name}'"
      )
    end

    #TODO document
    def dynamic_field_factory(field_name)
      dynamic_fields_hash[field_name.to_sym] || raise(
        UnrecognizedFieldError,
        "No dynamic field configured for #{@types * ', '} with name #{field_name.inspect}"
      )
    end

    def text_fields
      @text_fields ||= text_fields_hash.values
    end

    def fields
      @fields ||= fields_hash.values
    end

    def dynamic_fields
      @dynamic_fields ||= fields_hash.values
    end

    private

    def text_fields_hash
      @text_fields_hash ||=
        setups.inject({}) do |hash, setup|
          setup.text_fields.each do |text_field|
            hash[text_field.name] ||= text_field
          end
          hash
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
      @fields_hash ||=
        begin
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

    def dynamic_fields_hash
      @dynamic_fields_hash ||=
        begin
          dynamic_fields_hash = @types.inject({}) do |hash, type|
            Setup.for(type).dynamic_field_factories.each do |field_factory|
              (hash[field_factory.name.to_sym] ||= {})[type.name] = field_factory
            end
            hash
          end
          dynamic_fields_hash.each_pair do |field_name, field_configurations_hash|
            if @types.any? { |type| field_configurations_hash[type.name].nil? }
              dynamic_fields_hash.delete(field_name)
            else
              dynamic_fields_hash[field_name] = field_configurations_hash.values.first
            end
          end
        end
    end
  end
end
