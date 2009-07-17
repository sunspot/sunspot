module Sunspot
  class QueryFacet
    def initialize(outgoing_query_facet, row_data)
      @outgoing_query_facet, @row_data = outgoing_query_facet, row_data
    end

    def rows
      rows = []
      for row in  @outgoing_query_facet.rows
        row_query = row.to_boolean_phrase
        if @row_data.has_key?(row_query)
          rows << QueryFacetRow.new(row.label, @row_data[row_query])
        end
      end
      rows.sort! { |x, y| y.count <=> x.count }
    end
  end
end
