module Sunspot
  module DSL
    class Fields
      def initialize(setup)
        @setup = setup
      end

      def text(*names, &block)
        for name in names
          @setup.add_text_fields(build_field(name, ::Sunspot::Type::TextType, &block))
        end
      end

      def method_missing(method, *args, &block)
        begin
          type = ::Sunspot::Type.const_get("#{method.to_s.camel_case}Type")
        rescue(NameError)
          super(method.to_sym, *args, &block) and return
        end
        name = args.shift
        @setup.add_fields(build_field(name, type, *args, &block))
      end

      private

      def build_field(name, type, *args, &block)
        options = args.shift if args.first.is_a?(Hash)
        unless block
          ::Sunspot::Field::AttributeField.new(name, type, options || {})
        else
          ::Sunspot::Field::VirtualField.new(name, type, options || {}, &block)
        end
      end
    end
  end
end
