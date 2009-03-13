module Sunspot
  module Field
    class Base
      attr_accessor :name, :type

      def initialize(name, type, options = {})
        @name, @type = name, type
        @multiple = options.delete(:multiple)
        raise ArgumentError, "Unknown field option #{options.keys.first.inspect} provided for field #{name.inspect}" unless options.empty?
      end

      def pair_for(model)
        if value = value_for(model)
          { indexed_name.to_sym => to_indexed(value) }
        else
          {}
        end
      end

      def indexed_name
        "#{type.indexed_name(name)}#{'m' if multiple?}"
      end

      def to_indexed(value)
        if value.kind_of? Array 
          if multiple?
            value.map { |val| to_indexed(val) }
          else
            raise ArgumentError, "#{name} is not a multiple-value field, so it cannot index values #{value.inspect}"
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

      def value_for(model)
        model.instance_eval(&@block)
      end
    end
  end
end
