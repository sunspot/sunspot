module Sunspot
  class FieldBuilder
    def initialize(clazz)
      @clazz = clazz
    end

    def text(*names, &block)
      for name in names
        ::Sunspot::Field.register_text clazz, build_field(name, ::Sunspot::Type::TextType, &block)
      end
    end

    def method_missing(method, *args, &block)
      begin
        type = ::Sunspot::Type.const_get "#{method.to_s.camel_case}Type"
      rescue(NameError)
        super(method.to_sym, *args, &block) and return
      end
      name = args.shift
      ::Sunspot::Field.register clazz, build_field(name, type, *args, &block)
    end

    protected
    attr_reader :clazz

    private

    def build_field(name, type, *args, &block)
      unless block
        ::Sunspot::Field::AttributeField.new(name, type)
      else
        ::Sunspot::Field::VirtualField.new(name, type, &block)
      end
    end
  end
end
