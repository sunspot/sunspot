module Sunspot
  class Indexer
    def initialize(connection, setup)
      @connection, @setup = connection, setup
    end

    def add(model)
      hash = static_hash_for(model)
      for field in @setup.all_fields
        hash.merge!(field.pair_for(model))
      end
      @connection.add(hash)
    end

    def remove(model)
      @connection.delete(::Sunspot::Adapters::InstanceAdapter.adapt(model).index_id)
    end

    protected 

    def static_hash_for(model)
      { :id => ::Sunspot::Adapters::InstanceAdapter.adapt(model).index_id,
        :type => Indexer.superclasses_for(model.class).map { |clazz| clazz.name }}
    end
  end

  class <<Indexer
    def remove_all(connection, clazz = nil)
      connection.delete_by_query("type:#{clazz ? clazz.name : '[* TO *]'}")
    end

    def superclasses_for(clazz)
      superclasses_for = [clazz]
      superclasses_for << (clazz = clazz.superclass) while clazz.superclass != Object
      superclasses_for
    end
  end
end
