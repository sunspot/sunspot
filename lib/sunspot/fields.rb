module Sunspot
  module Fields
  end

  class <<Fields
    def add(clazz, fields)
      fields = [fields] unless fields.kind_of? Enumerable
      self.for(clazz).concat fields
    end

    def add_keywords(clazz, fields)
      fields = [fields] unless fields.kind_of? Enumerable
      self.keywords_for(clazz).concat fields
    end

    def for(clazz)
      fields_hash[clazz.object_id] ||= []
    end

    def keywords_for(clazz)
      keyword_fields_hash[clazz.object_id] ||= []
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
