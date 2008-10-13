module Sunspot
  module Index
    class Indexer
      def initialize(connection)
        @connection = connection
      end

      def add(model)
        if model.kind_of? Enumerable
          model.each { |mod| self.add mod }
        else
          connection.add(fields.inject(:id => "#{model.class.name}:#{model.id}",
                                       :type => Indexer.superclasses_for(model.class).map { |clazz| clazz.name }) do |hash, field|
            hash.merge! field.pair_for(model)
            hash
          end)
        end
      end

      def fields
        fields_hash.values
      end

      def add_fields(fields)
        for field in fields
          fields_hash[field.name] = field
        end
      end

      private
      attr_reader :connection

      def fields_hash
        @fields_hash ||= {}
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
end
