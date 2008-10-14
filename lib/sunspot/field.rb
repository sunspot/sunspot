module Sunspot
  module Field
    class Base
      attr_accessor :name, :type

      def pair_for(model)
        if value = value_for(model)
          { type.indexed_name(name).to_sym => to_indexed(value) }
        else
          {}
        end
      end

      protected

      def to_indexed(value)
        if value.kind_of? Array 
          value.map { |val| to_indexed(val) }
        else
          type.to_indexed(value)
        end
      end
    end

    class AttributeField < ::Sunspot::Field::Base
      def initialize(name, type)
        @name, @type = name, type
      end

      protected

      def value_for(model)
        model.send(name)
      end
    end

    class VirtualField < ::Sunspot::Field::Base
      def initialize(name, type, &block)
        @name, @type, @block = name, type, block
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
  end
end
