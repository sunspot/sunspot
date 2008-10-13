module Sunspot
  class VirtualField
    attr_accessor :name, :type

    def initialize(name, type, &block)
      @name, @type, @block = name, type, block
    end

    def pair_for(model)
      if value = value_for(model)
        { type.indexed_name(name).to_sym => to_indexed(value) }
      else
        {}
      end
    end

    protected
    attr_accessor :block

    private
    
    def to_indexed(value)
      if value.kind_of? Array
        value.map { |val| to_indexed(val) }
      else
        type.to_indexed(value)
      end
    end

    def value_for(model)
      model.instance_eval(&block)
    end
  end
end
