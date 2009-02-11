module Sunspot
  module Field
    class Base
      attr_accessor :name, :type

      def initialize(name, type, options = {})
        @name, @type = name, type
        @multiple = options.delete(:multiple)
        if unknown_key = options.keys.first
          raise ArgumentError,
                "Unknown field option #{unknown_key.inspect}"
                "provided for field #{name.inspect}"
        end
      end

      def pair_for(model)
        if value = value_for(model)
          { indexed_name.to_sym => to_indexed(value) }
        else
          {}
        end
      end

      def ==(other)
        other.respond_to?(:name) &&
          other.respond_to?(:type) &&
          self.name == other.name &&
          self.type == other.type
      end

      def hash
        name.hash + 31 * type.hash
      end

      def indexed_name
        "#{type.indexed_name(name)}#{'m' if multiple?}"
      end

      def to_indexed(value)
        if value.kind_of?(Array)
          if multiple?
            value.map { |val| to_indexed(val) }
          else
            raise ArgumentError,
                  "#{name} is not a multiple-value field, so it cannot"
                  " index values #{value.inspect}"
          end
        else
          type.to_indexed(value)
        end
      end

      def multiple?
        !!@multiple
      end
    end

    class AttributeField < ::Sunspot::Field::Base
      protected

      def value_for(model)
        model.send(name)
      end
    end

    class VirtualField < ::Sunspot::Field::Base
      def initialize(name, type, options = {}, &block)
        super(name, type, options)
        @block = block
      end

      protected
      attr_accessor :block

      def value_for(model)
        model.instance_eval(&block)
      end
    end
  end

  class <<Field
    def register(clazz, fields)
      fields = [fields] unless fields.kind_of? Enumerable
      self.for(clazz).concat fields
    end

    def register_text(clazz, fields)
      fields = [fields] unless fields.kind_of? Enumerable
      self.text_for(clazz).concat fields
    end

    def text_for(clazz)
      keyword_fields_hash[clazz.object_id] ||= []
    end

    def for(clazz)
      fields_hash[clazz.object_id] ||= []
    end

    def unregister_all!
      fields_hash.clear
    end

    private

    def fields_hash
      @fields_hash ||= {}
    end

    def keyword_fields_hash
      @keyword_fields_hash ||= {}
    end
  end
end
