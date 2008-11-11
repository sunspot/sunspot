module Sunspot
  module Adapters
    module InstanceAdapter
      def initialize(instance)
        @instance = instance
      end

      def index_id
        "#{instance.class.name} #{id}"
      end

      protected
      attr_accessor :instance
    end

    module ClassAdapter
      def initialize(clazz)
        @clazz = clazz
      end

      protected
      attr_reader :clazz
    end
  end

  class <<Adapters
    def register(adapter, *classes)
      for clazz in classes
        adapters[clazz.name] = adapter
      end
    end

    def for(clazz)
      while clazz != Object
        return adapters[clazz.name] if adapters[clazz.name]
        clazz = clazz.superclass
      end
    end

    private

    def adapters
      @adapters ||= {}
    end
  end
end
