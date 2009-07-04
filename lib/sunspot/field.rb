module Sunspot
  # 
  # The Field functionality in Sunspot is comprised of two roles:
  #
  # Field definitions::
  #   Field definitions encompass the information that the user enters when
  #   setting up the field, such as field name, type of access, data type,
  #   whether multiple values are allowed, etc.
  #   They are also capable of extracting data from a model in a format
  #   that can be passed directly to the indexer.
  # Field instances::
  #   Field instances represent an actual field in Solr; thus, they are able to
  #   return the indexed field name, convert the value to its appropriate type,
  #   etc.
  #
  # StaticField objects play both the definition and the instance role.
  # DynamicField objects act only as definitions, and spawn DynamicFieldInstance
  # objects to play the instance role.
  # 
  module Field #:nodoc: all
    #
    # The FieldInstance module encapsulates functionality associated with
    # acting as a concrete instance of a field for the purposes of search.
    # In particular, FieldInstances need to be able to return indexed names,
    # convert values to their indexed representation, and cast returned values
    # to the appropriate native Ruby type.
    # 
    module FieldInstance
      # The name of the field as it is indexed in Solr. The indexed name
      # contains a suffix that contains information about the type as well as
      # whether the field allows multiple values for a document.
      #
      # ==== Returns
      #
      # String:: The field's indexed name
      #
      def indexed_name
        "#{@type.indexed_name(name)}#{'m' if @multiple}"
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
    end

    # 
    # This module adds a (class) method for building a field definition given
    # a standard set of arguments
    # 
    module Buildable
      #
      # Build a field definition based on a standard argument API. If a block
      # is passed, use virtual extraction; otherwise, use attribute extraction.
      # 
      def build(name, type, options = {}, &block)
        data_extractor =
          if block
            DataExtractor::BlockExtractor.new(&block)
          else
            DataExtractor::AttributeExtractor.new(options.delete(:using) || name)
          end
        new(name, type, data_extractor, options)
      end
    end

    #
    # Field classes encapsulate information about a field that has been configured
    # for search and indexing. They expose methods that are useful for both
    # operations.
    #
    # Subclasses of Field::Base must implement the method #value_for
    #
    class StaticField
      include FieldInstance
      extend Buildable

      attr_accessor :name # The public-facing name of the field
      attr_accessor :type # The Type of the field
      attr_accessor :reference # Model class that the value of this field refers to

      def initialize(name, type, data_extractor, options = {}) #:nodoc
        unless name.to_s =~ /^\w+$/
          raise ArgumentError, "Invalid field name #{name}: only letters, numbers, and underscores are allowed."
        end
        @name, @type, @data_extractor = name.to_sym, type, data_extractor
        #FIXME seems like this could be done more elegantly
        @attributes = {}
        if @type == Sunspot::Type::TextType
          if options.has_key?(:boost)
            @attributes[:boost] = options.delete(:boost)
          end
        else
          @multiple = !!options.delete(:multiple)
          @reference =
            if (reference = options.delete(:references)).respond_to?(:name)
              reference.name
            elsif reference.respond_to?(:to_sym)
              reference.to_sym
            end
        end
        raise ArgumentError, "Unknown field option #{options.keys.first.inspect} provided for field #{name.inspect}" unless options.empty?
      end

      # A key-value pair where the key is the field's indexed name and the
      # value is the value that should be indexed for the given model. This can
      # be merged directly into the document hash for adding to solr-ruby.
      #
      # ==== Parameters
      #
      # model<Object>:: the model from which to extract the value
      #
      # ==== Returns
      #
      # Hash:: a single key-value pair with the field name and value
      #
      def populate_document(document, model) #:nodoc:
        unless (value = @data_extractor.value_for(model)).nil?
          for scalar_value in Array(to_indexed(value))
            document.add_field(indexed_name.to_sym, scalar_value, @attributes)
          end
        end
      end
    end

    # 
    # A DynamicField is a field definition that allows actual fields to be
    # dynamically specified at search/index time. Indexed objects specify
    # the actual fields to be indexed using a hash, whose keys are the dynamic
    # field names and whose values are the values to be indexed.
    #
    # When indexed, dynamic fields are stored using the dynamic field's base
    # name, and the runtime-specified dynamic name, separated by a colon. Since
    # colons are not permitted in static Sunspot field names, namespace
    # collisions are prevented.
    # 
    # The use cases for dynamic fields are fairly limited, but certain
    # applications with highly dynamic data models might find them userful.
    # 
    class DynamicField
      extend Buildable

      attr_accessor :name # Base name of the dynamic field.
      attr_accessor :type # Type of the field

      def initialize(name, type, data_extractor, options)
        @name, @type, @data_extractor = name, type, data_extractor
        @multiple = !!options.delete(:multiple)
      end

      # 
      # Return a hash whose keys are fully-qualified field names and whose
      # values are values to be indexed, representing the data to be indexed
      # by this field definition for this model.
      #
      # ==== Parameters
      #
      # model<Object>:: the model from which to extract the value
      #
      # ==== Returns
      #
      # Hash::
      #   Key-value pairs representing field names and values to be indexed.
      #
      # 
      def populate_document(document, model)
        if values = @data_extractor.value_for(model)
          values.each_pair do |dynamic_name, value|
            field_instance = build(dynamic_name)
            for scalar_value in Array(field_instance.to_indexed(value))
              document.add_field(field_instance.indexed_name.to_sym, scalar_value)
            end
          end
        end
      end

      # 
      # Build a DynamicFieldInstance representing an actual field to be indexed
      # or searched in Solr.
      # 
      # ==== Parameters
      #
      # dynamic_name<Symbol>:: dynamic name for the field instance
      #
      # ==== Returns
      # 
      # DynamicFieldInstance:: Dynamic field instance
      # 
      def build(dynamic_name)
        DynamicFieldInstance.new(@name, dynamic_name, @type, @data_extractor, @multiple)
      end
    end

    # 
    # This class represents actual dynamic fields as they are indexed in Solr.
    # Thus, they have knowledge of the base name and dynamic name, type, etc.
    # 
    class DynamicFieldInstance
      include FieldInstance
      attr_reader :reference

      def initialize(base_name, dynamic_name, type, data_extractor, multiple)
        @base_name, @dynamic_name, @type, @data_extractor, @multiple =
          base_name, dynamic_name, type, data_extractor, multiple
      end

      protected

      def name
        "#{@base_name}:#{@dynamic_name}"
      end
    end
  end
end
