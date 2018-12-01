require File.join(File.dirname(__FILE__), 'post')

module MockAdapter
  class InstanceAdapter < Sunspot::Adapters::InstanceAdapter
    def id
      @instance.id
    end
  end

  class DataAccessor < Sunspot::Adapters::DataAccessor
    def load(id)
      @clazz.get(id.to_i)
    end

    def load_all(ids)
      all = @clazz.get_all(ids.map { |id| id.to_i })
      if @custom_title
        all.each { |item| item.title = @custom_title }
      end
      all
    end

    def custom_title=(custom_title)
      @custom_title = custom_title
    end
  end
end

Sunspot::Adapters::DataAccessor.register(MockAdapter::DataAccessor, MockRecord)
Sunspot::Adapters::InstanceAdapter.register(MockAdapter::InstanceAdapter, MockRecord)
