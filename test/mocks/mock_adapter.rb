require File.join(File.dirname(__FILE__), 'post')

module MockAdapter
  class InstanceAdapter
    include Sunspot::Adapters::InstanceAdapter
    
    def id
      instance.id
    end
  end

  class ClassAdapter
    include Sunspot::Adapters::ClassAdapter

    def load(id)
      clazz.get(id.to_i)
    end

    def load_all(ids)
      clazz.get_all(ids.map { |id| id.to_i })
    end
  end
end

Sunspot::Adapters.register(MockAdapter, BaseClass)
