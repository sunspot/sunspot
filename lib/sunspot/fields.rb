module Sunspot
  module Fields
  end

  class <<Fields
    def add(clazz, fields)
      (fields_hash[clazz.object_id] ||= []).concat fields
    end

    def for(clazz)
      fields_hash[clazz.object_id] || []
    end

    private

    def fields_hash
      @fields_hash ||= {}
    end
  end
end
