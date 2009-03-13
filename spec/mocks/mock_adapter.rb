require File.join(File.dirname(__FILE__), 'post')

module MockAdapter
  class InstanceAdapter < Sunspot::Adapters::InstanceAdapter
    def id
      instance.id
    end
  end

  class DataAccessor < Sunspot::Adapters::DataAccessor
    def load(id)
      clazz.get(id.to_i)
    end

    def load_all(ids)
      clazz.get_all(ids.map { |id| id.to_i })
    end
  end
end

Sunspot::Adapters::DataAccessor.register(MockAdapter::DataAccessor, BaseClass)
Sunspot::Adapters::InstanceAdapter.register(MockAdapter::InstanceAdapter, BaseClass)
