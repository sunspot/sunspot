module Sunspot
  module Field #:nodoc[all]
    #
    # Field classes encapsulate information about a field that has been configured
    # for search and indexing. They expose methods that are useful for both
    # operations.
    #
    # Subclasses of Field::Base must implement the method #value_for
    #
    class Base
      attr_accessor :name # The public-facing name of the field
      attr_accessor :type # The Type of the field

      def initialize(name, type, options = {}) #:nodoc
        @name, @type = name, type
        @multiple = options.delete(:multiple)
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
      def pair_for(model)
        if value = value_for(model)
          { indexed_name.to_sym => to_indexed(value) }
        else
          {}
        end
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
        "#{type.indexed_name(name)}#{'m' if multiple?}"
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
          if multiple?
            value.map { |val| to_indexed(val) }
          else
            raise ArgumentError, "#{name} is not a multiple-value field, so it cannot index values #{value.inspect}"
          end
        else
          type.to_indexed(value)
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
        type.cast(value)
      end

      # ==== Returns
      #
      # Boolean:: true if the field allows multiple values; false if not
      def multiple?
        !!@multiple
      end
    end

    #
    # AttributeFields call methods directly on indexed objects and index the
    # return value of the method.
    #
    class AttributeField < Base
      protected

      #
      # Call the method named by the field name and return its value
      #
      # ==== Parameters
      #
      # model<Object>:: The object from which to extract the value
      #
      # ==== Returns
      #
      # Object:: The value to index
      #
      def value_for(model)
        model.send(name)
      end
    end

    #
    # VirtualFields extract data by evaluating the provided block in the context
    # of the model instance.
    #
    class VirtualField < Base
      def initialize(name, type, options = {}, &block)
        super(name, type, options)
        @block = block
      end

      protected

      # 
      # Evaluate the block in the model's context and return the block's return
      # value.
      #
      # ==== Parameters
      #
      # model<Object>:: The object from which to extract the value
      #
      # ==== Returns
      #
      # Object:: The value to index
      def value_for(model)
        model.instance_eval(&@block)
      end
    end
  end
end
