module Sunspot
  class FieldBuilder
    def initialize(clazz)
      @clazz = clazz
    end

    def method_missing(method, *args, &block)
      begin
        type = ::Sunspot::Type.const_get method.to_s.upcase 
      rescue(NameError)
        super(method.to_sym, *args, &block) and return
      end
      name = args.shift
      build_field(name, type, *args, &block)
    end

    private
    attr_reader :clazz

    def build_field(name, type, *args, &block)
      unless block
        Sunspot::Fields.add clazz, Sunspot::AttributeField.new(name, type)
      else
        Sunspot::Fields.add clazz, Sunspot::VirtualField.new(name, type, &block)
      end
    end
  end
end
