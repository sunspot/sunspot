module Sunspot
  class Indexer
    def initialize(connection)
      @connection = connection
    end

    def add(model)
      if model.kind_of? Enumerable
        model.each { |mod| self.add mod }
      else
        hash = static_hash_for model
        for field in fields
          hash.merge! field.pair_for(model)
        end
        connection.add hash
      end
    end

    def fields
      @fields ||= []
    end

    def add_fields(fields)
      self.fields.concat fields
    end

    protected 
    attr_reader :connection

    def static_hash_for(model)
      { :id => "#{model.class.name}:#{model.id}",
        :type => Indexer.superclasses_for(model.class).map { |clazz| clazz.name }}
    end
  end

  class <<Indexer
    def add(model)
      self.for(model.class).add model
    end

    def for(clazz, connection = nil)
      connection ||= Solr::Connection.new('http://localhost:8983/solr')
      indexer = self.new(connection)
      for superclass in superclasses_for(clazz)
        indexer.add_fields ::Sunspot::Fields.for(superclass)
        indexer.add_fields ::Sunspot::Fields.keywords_for(superclass)
      end
      indexer
    end

    def superclasses_for(clazz)
      superclasses_for = [clazz]
      superclasses_for << (clazz = clazz.superclass) while clazz.superclass != Object
      superclasses_for
    end
  end
end
