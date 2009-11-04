require 'enumerator'

module Sunspot
  class Search
    class FieldFacet < QueryFacet
      include FacetInstancePopulator

      def initialize(field, search)
        super(field.name, search, {}, field)
      end

      def rows
        @rows ||=
          begin
            rows = super
            if @search.facet_response['facet_fields']
              if data = @search.facet_response['facet_fields'][@field.indexed_name]
                data.each_slice(2) do |value, count|
                  rows << FacetRow.new(@field.cast(value), count, self)
                end
              end
            end
            rows
          end
      end
    end
  end
end
