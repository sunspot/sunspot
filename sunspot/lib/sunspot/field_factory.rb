module Sunspot
  # 
  # The FieldFactory module contains classes for generating fields. FieldFactory
  # implementation classes should implement a #build method, although the arity
  # of the method depends on the type of factory. They also must implement a
  # #populate_document method, which extracts field data from a given model and
  # adds it into the Solr document for indexing.
  #
  module FieldFactory #:nodoc:all
    # 
    # Base class for field factories.
    #
    class Abstract
      attr_reader :name

      def initialize(name, options = {}, &block)
        @name = name.to_sym
        @data_extractor =
          if block
            DataExtractor::BlockExtractor.new(&block)
          else
            DataExtractor::AttributeExtractor.new(options.delete(:using) || name)
          end
      end
    end

    # 
    # A StaticFieldFactory generates normal static fields. Each factory instance
    # contains an eager-initialized field instance, which is returned by the
    # #build method.
    #
    class Static < Abstract
      def initialize(name, type, options = {}, &block)
        super(name, options, &block)
        unless name.to_s =~ /^\w+$/
          raise ArgumentError, "Invalid field name #{name}: only letters, numbers, and underscores are allowed."
        end
        @field =
          if type.is_a?(Type::TextType)
            FulltextField.new(name, options)
          else
            AttributeField.new(name, type, options)
          end
      end

      # 
      # Return the field instance built by this factory
      #
      def build
        @field
      end

      # 
      # Extract the encapsulated field's data from the given model and add it
      # into the Solr document for indexing.
      #
      def populate_document(document, model) #:nodoc:
        unless (value = @data_extractor.value_for(model)).nil?
          Util.Array(@field.to_indexed(value)).each do |scalar_value|
            options = {}
            options[:boost] = @field.boost if @field.boost
            document.add_field(
              @field.indexed_name.to_sym,
              scalar_value,
              options
            )
          end
        end
      end

      # 
      # A unique signature identifying this field by name and type.
      #
      def signature
        [@field.name, @field.type]
      end
    end

    class Join < Abstract
      def initialize(name, type, options = {}, &block)
        super(options[:prefix] ? "#{options[:prefix]}_#{name}" : name, options, &block)
        unless name.to_s =~ /^\w+$/
          raise ArgumentError, "Invalid field name #{name}: only letters, numbers, and underscores are allowed."
        end
        @field = JoinField.new(self.name, type, options)
      end

      # 
      # Return the field instance built by this factory
      #
      def build
        @field
      end

      # 
      # Extract the encapsulated field's data from the given model and add it
      # into the Solr document for indexing. (noop here for joins)
      #
      def populate_document(document, model) #:nodoc:
      end

      # 
      # A unique signature identifying this field by name and type.
      #
      def signature
        ['join', @field.name, @field.type]
      end
    end

    # 
    # DynamicFieldFactories create dynamic field instances based on dynamic
    # configuration.
    #
    class Dynamic < Abstract
      attr_accessor :name, :type, :separator

      def initialize(name, type, options = {}, &block)
        super(name, options, &block)
        @type, @options = type, options
        @separator = @options.delete(:separator) || ':'
      end

      #
      # Build a field based on the dynamic name given.
      #
      def build(dynamic_name)
        AttributeField.new([@name, dynamic_name].join(separator), @type, @options.dup)
      end
      # 
      # This alias allows a DynamicFieldFactory to be used in place of a Setup
      # or CompositeSetup instance by query components.
      #
      alias_method :field, :build

      # 
      # Generate dynamic fields based on hash returned by data accessor and
      # add the field data to the document.
      #
      def populate_document(document, model)
        if values = @data_extractor.value_for(model)
          values.each_pair do |dynamic_name, value|
            field_instance = build(dynamic_name)
            Util.Array(field_instance.to_indexed(value)).each do |scalar_value|
              document.add_field(
                field_instance.indexed_name.to_sym,
                scalar_value
              )
            end
          end
        end
      end

      # 
      # Unique signature identifying this dynamic field based on name and type
      #
      def signature
        [@name, @type]
      end
    end
  end
end
