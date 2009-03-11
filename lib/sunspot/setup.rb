module Sunspot
  class Setup
    def initialize(clazz)
      @class_name = clazz.name
      @fields, @text_fields = [], []
      @dsl = Sunspot::DSL::Fields.new(self)
    end

    def add_fields(fields)
      @fields.concat(Array(fields))
    end

    def add_text_fields(fields)
      @text_fields.concat(Array(fields))
    end

    def setup(&block)
      @dsl.instance_eval(&block)
    end

    def fields
      fields = @fields.dup
      fields.concat(parent.fields) if parent
      fields
    end

    def text_fields
      text_fields = @text_fields.dup
      text_fields.concat(parent.text_fields) if parent
      text_fields
    end

    def all_fields
      fields + text_fields
    end

    def indexer(connection)
      Sunspot::Indexer.new(connection, self)
    end

    protected

    def parent
      Setup.for(clazz.superclass)
    end

    def clazz
      Object.full_const_get(@class_name)
    end


    class <<self
      def setup(clazz, &block)
        self.for!(clazz).setup(&block)
      end

      def for(clazz)
        setups[clazz.name] || self.for(clazz.superclass) if clazz
      end

      def for!(clazz)
        setups[clazz.name] ||= new(clazz)
      end

      private

      def setups
        @setups ||= {}
      end
    end
  end
end
