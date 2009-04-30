module Sunspot
  module Rails
    module Adapters
      class ActiveRecordInstanceAdapter < Sunspot::Adapters::InstanceAdapter
        def id
          @instance.id
        end
      end

      class ActiveRecordDataAccessor < Sunspot::Adapters::DataAccessor
        def load(id)
          @clazz.find(id)
        end

        def load(ids)
          @clazz.find(ids)
        end
      end
    end
  end
end
