module Sunspot
  class Field #:nodoc:
    attr_accessor :name # The public-facing name of the field
    attr_accessor :type # The Type of the field
    attr_accessor :reference # Model class that the value of this field refers to
    attr_accessor :attributes

    # 
    #
    def initialize(name, type) #:nodoc
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

    # 
    # Name with which this field is indexed internally. Based on public name and
    # type.
    #
    # ==== Returns
    #
    # String:: Internal name of the field
    #
    def indexed_name
      @type.indexed_name(@name)
    end

    # 
    # Whether this field accepts multiple values.
    #
    # ==== Returns
    #
    # Boolean:: True if this field accepts multiple values.
    #
    def multiple?
      !!@multiple
    end
  end

  # 
  # FulltextField instances represent fields that are indexed as fulltext.
  # These fields are tokenized in the index, and can have boost applied to
  # them. They also always allow multiple values (since the only downside of
  # allowing multiple values is that it prevents the field from being sortable,
  # and sorting on tokenized fields is nonsensical anyway, there is no reason
  # to do otherwise). FulltextField instances always have the type TextType.
  #
  class FulltextField < Field #:nodoc:
    def initialize(name, options = {})
      super(name, Type::TextType)
      if options.has_key?(:boost)
        @attributes[:boost] = options.delete(:boost)
      end
      @multiple = true
      raise ArgumentError, "Unknown field option #{options.keys.first.inspect} provided for field #{name.inspect}" unless options.empty?
    end
  end

  # 
  # AttributeField instances encapsulate non-tokenized attribute data.
  # AttributeFields can have any type except TextType, and can also have
  # a reference (for instantiated facets), optionally allow multiple values
  # (false by default), and can store their values (false by default). All
  # scoping, sorting, and faceting is done with attribute fields.
  #
  class AttributeField < Field #:nodoc:
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

  # 
  # RandomField instances are used for random sorting.
  #
  class RandomField #:nodoc:
    # 
    # Never multiple, but this has to return false so Sunspot doesn't barf
    # when you try to order by it.
    #
    def multiple?
      false
    end

    # 
    # Solr uses the dynamic field name as a seed for random, so we randomize the
    # field name accordingly.
    #
    # #XXX I think it's bad to use a random number as a seed. Would it be
    # better to pass in the current timestamp or some such thing?
    #
    def indexed_name
      "random_#{rand(1<<16)}"
    end
  end
end
