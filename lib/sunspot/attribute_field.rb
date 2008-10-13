module Sunspot
  class AttributeField
    attr_accessor :name, :type

    def initialize(name, type)
      @name, @type = name, type
    end

    def pair_for(model)
      if value = model.send(name)
        { type.indexed_name(name).to_sym => type.to_indexed(value) }
      else
        {}
      end
    end
  end
end
