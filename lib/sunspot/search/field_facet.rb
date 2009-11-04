require 'enumerator'

module Sunspot
  class Search
    class FieldFacet
      include FacetInstancePopulator

      def initialize(field, search)
        @field, @search = field, search
      end

      def field_name
        @field.name
      end

      def rows
        @rows ||=
          begin
            data = @search.facet_response['facet_fields'][@field.indexed_name]
            rows = []
            data.each_slice(2) do |value, count|
              rows << FacetRow.new(@field.cast(value), count, self)
            end
            rows
          end
      end
    end
  end
end
