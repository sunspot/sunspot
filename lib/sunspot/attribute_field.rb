module Sunspot
  class AttributeField
    attr_accessor :name, :type

    def initialize(name, type)
      @name, @type = name, type
    end

    def pair_for(model)
      if value = value_for(model)
        { type.indexed_name(name).to_sym => to_indexed(value) }
      else
        {}
      end
    end

    private

    def to_indexed(value)
      if value.kind_of? Array 
        value.map { |val| to_indexed(val) }
      else
        type.to_indexed(value)
      end
    end

    def value_for(model)
      model.send(name)
    end
  end
end
