module Sunspot
  module FieldFactory
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

    class Static < Abstract
      def initialize(name, type, options = {}, &block)
        super(name, options, &block)
        unless name.to_s =~ /^\w+$/
          raise ArgumentError, "Invalid field name #{name}: only letters, numbers, and underscores are allowed."
        end
        @field =
          if type == Type::TextType
            FulltextField.new(name, options)
          else
            AttributeField.new(name, type, options)
          end
      end

      def build
        @field
      end

      def populate_document(document, model) #:nodoc:
        unless (value = @data_extractor.value_for(model)).nil?
          for scalar_value in Array(@field.to_indexed(value))
            document.add_field(
              @field.indexed_name.to_sym,
              scalar_value, @field.attributes
            )
          end
        end
      end

      def signature
        [@field.name, @field.type]
      end
    end

    class Dynamic < Abstract
      attr_accessor :name, :type

      def initialize(name, type, options = {}, &block)
        super(name, options, &block)
        @type, @options = type, options
      end

      def build(dynamic_name)
        AttributeField.new("#{@name}:#{dynamic_name}", @type, @options.dup)
      end

      def populate_document(document, model)
        if values = @data_extractor.value_for(model)
          values.each_pair do |dynamic_name, value|
            field_instance = build(dynamic_name)
            for scalar_value in Array(field_instance.to_indexed(value))
              document.add_field(
                field_instance.indexed_name.to_sym,
                scalar_value
              )
            end
          end
        end
      end

      def signature
        [@name, @type]
      end
    end
  end
end
