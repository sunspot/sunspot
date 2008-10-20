module Sunspot
  module Condition
    class Base
      def initialize(field, value)
        @field, @value = field, value
      end

      def to_solr_query
        "#{field.indexed_name}:#{to_solr_conditional}"
      end

      protected
      attr_accessor :field, :value

      def solr_value(value = self.value)
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
  end
end
