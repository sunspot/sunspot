module Sunspot
  class Field
    attr_accessor :name # The public-facing name of the field
    attr_accessor :type # The Type of the field
    attr_accessor :reference # Model class that the value of this field refers to
    attr_accessor :attributes

    def initialize(name, type) #:nodoc
      debugger if type.is_a?(Hash)
      @name, @type = name.to_sym, type
      @attributes = {}
    end

    # Convert a value to its representation for Solr indexing. This delegates
    # to the #to_indexed method on the field's type.
    #
    # ==== Parameters
    #
    # value<Object>:: Value to convert to Solr representation
    #
    # ==== Returns
    #
    # String:: Solr representation of the object
    #
    # ==== Raises
    #
    # ArgumentError::
    #   the value is an array, but this field does not allow multiple values
    #
    def to_indexed(value)
      if value.is_a? Array
        if @multiple
          value.map { |val| to_indexed(val) }
        else
          raise ArgumentError, "#{name} is not a multiple-value field, so it cannot index values #{value.inspect}"
        end
      else
        @type.to_indexed(value)
      end
    end

    # Cast the value into the appropriate Ruby class for the field's type
    #
    # ==== Parameters
    #
    # value<String>:: Solr's representation of the value
    #
    # ==== Returns
    #
    # Object:: The cast value
    #
    def cast(value)
      @type.cast(value)
    end

    def indexed_name
      @type.indexed_name(@name)
    end

    def multiple?
      !!@multiple
    end
  end

  class FulltextField < Field
    def initialize(name, options = {})
      super(name, Type::TextType)
      if options.has_key?(:boost)
        @attributes[:boost] = options.delete(:boost)
      end
      @multiple = true
      raise ArgumentError, "Unknown field option #{options.keys.first.inspect} provided for field #{name.inspect}" unless options.empty?
    end
  end

  class AttributeField < Field
    def initialize(name, type, options = {})
      super(name, type)
      @multiple = !!options.delete(:multiple)
      @reference =
        if (reference = options.delete(:references)).respond_to?(:name)
          reference.name
        elsif reference.respond_to?(:to_sym)
          reference.to_sym
        end
      @stored = !!options.delete(:stored)
      raise ArgumentError, "Unknown field option #{options.keys.first.inspect} provided for field #{name.inspect}" unless options.empty?
    end

    # The name of the field as it is indexed in Solr. The indexed name
    # contains a suffix that contains information about the type as well as
    # whether the field allows multiple values for a document.
    #
    # ==== Returns
    #
    # String:: The field's indexed name
    #
    def indexed_name
      "#{super}#{'m' if @multiple}#{'s' if @stored}"
    end
  end
end
