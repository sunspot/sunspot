module Sunspot
  module Search
    class FieldStats
      def initialize(field, search) #:nodoc:
        @field, @search = field, search
        @facets = []
      end

      def add_facet field
        @facets << field
      end

      def field_name
        @field.name
      end

      def min
        row.min
      end

      def max
        row.max
      end

      def count
        row.count
      end

      def sum
        row.sum
      end

      def facet name
        row.facet(name)
      end

      private
      def row
        @row ||= StatsRow.new(
          @field, @search.stats_response[@field.indexed_name], @facets
        )
      end
    end
  end
end
