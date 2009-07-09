module Sunspot
  #TODO document
  class DateFacet < Facet
    def initialize(facet_values, field)
      @gap = facet_values.delete('gap')[/\+(\d+)SECONDS/,1].to_i
      super(facet_values.to_a.flatten, field)
    end

    def new_row(pair)
      DateFacetRow.new(pair, @gap, self)
    end
  end
end
