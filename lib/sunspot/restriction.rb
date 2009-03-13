module Sunspot
  module Restriction
    class <<self
      def names
        constants - %w(Base SameAs) #XXX this seems ugly
      end
    end

    class Base
      def initialize(field, value)
        @field, @value = field, value
      end

      def to_solr_query
        "#{field.indexed_name}:#{to_solr_conditional}"
      end

      def to_negative_solr_query
        "-#{to_solr_query}"
      end

      protected
      attr_accessor :field, :value

      def solr_value(value = @value)
        escape field.to_indexed(value)
      end

      def escape(value)
        Solr::Util.query_parser_escape value
      end
    end

    class EqualTo < Base
      private

      def to_solr_conditional
        "#{solr_value}"
      end
    end

    class LessThan < Base
      private

      def to_solr_conditional
        "[* TO #{solr_value}]"
      end
    end

    class GreaterThan < Base
      private

      def to_solr_conditional
        "[#{solr_value} TO *]"
      end
    end

    class Between < Base
      private

      def to_solr_conditional
        "[#{solr_value value.first} TO #{solr_value value.last}]"                  
      end
    end

    class AnyOf < Base
      private

      def to_solr_conditional
        "(#{value.map { |v| solr_value v } * ' OR '})"
      end
    end

    class AllOf < Base
      private

      def to_solr_conditional
        "(#{value.map { |v| solr_value v } * ' AND '})"
      end
    end

    class SameAs < Base
      def initialize(object)
        @object = object
      end

      def to_solr_query
        adapter = Sunspot::Adapters.adapt_instance(@object)
        "id:#{escape(adapter.index_id)}"
      end
    end
  end
end
