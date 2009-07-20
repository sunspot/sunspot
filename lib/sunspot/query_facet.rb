module Sunspot
  #
  # QueryFacet instances encapsulate a set of query facet results. Each facet
  # corresponds to a group of rows defined inside a DSL::FieldQuery#facet block.
  #
  class QueryFacet
    def initialize(outgoing_query_facet, row_data) #:nodoc:
      @outgoing_query_facet, @row_data = outgoing_query_facet, row_data
    end

    # 
    # Get the rows associated with this query facet. Returned rows are always
    # ordered by count.
    #
    # ==== Returns
    #
    # Array:: Collection of QueryFacetRow objects, ordered by count
    #
    def rows
      @rows ||=
        begin
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
end
