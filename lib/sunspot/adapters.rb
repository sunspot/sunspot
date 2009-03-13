module Sunspot
  module Adapters
    class InstanceAdapter
      def initialize(instance)
        @instance = instance
      end

      def index_id
        "#{instance.class.name} #{id}"
      end

      protected
      attr_accessor :instance

      class <<self
        def adapt(instance)
          self.for(instance.class).new(instance)
        end

        def register(instance_adapter, *classes)
          for clazz in classes
            instance_adapters[clazz.name] = instance_adapter
          end
        end

        def for(clazz)
          while clazz != Object
            return instance_adapters[clazz.name] if instance_adapters[clazz.name]
            clazz = clazz.superclass
          end
          nil
        end

        protected

        def instance_adapters
          @instance_adapters ||= {}
        end
      end
    end

    class DataAccessor
      def initialize(clazz)
        @clazz = clazz
      end

      protected
      attr_reader :clazz

      class <<self
        def create(clazz)
          self.for(clazz).new(clazz)
        end

        def register(data_accessor, *classes)
          for clazz in classes
            data_accessors[clazz.name] = data_accessor
          end
        end

        def for(clazz)
          while clazz != Object
            return data_accessors[clazz.name] if data_accessors[clazz.name]
            clazz = clazz.superclass
          end
        end

        protected

        def data_accessors
          @adapters ||= {}
        end
      end
    end
  end
end
