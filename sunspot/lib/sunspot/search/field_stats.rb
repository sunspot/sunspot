module Sunspot
  module Search
    class FieldStats < StatsRow
      def initialize(field, search) #:nodoc:
        @field, @search, @facet_fields = field, search, []
      end

      def add_facet field
        @facet_fields << field
      end

      def field_name
        @field.name
      end

      def data
        @search.stats_response[@field.indexed_name]
      end
    end
  end
end
