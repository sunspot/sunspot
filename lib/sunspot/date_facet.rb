module Sunspot
  #TODO document
  class DateFacet < Facet
    def initialize(facet_values, field)
      @gap = facet_values.delete('gap')[/\+(\d+)SECONDS/,1].to_i
      super(facet_values.to_a.flatten, field)
    end

    # The date facet info comes back from Solr as a hash, so we need to sort
    # it manually. FIXME this currently assumes we want to do a "lexical"
    # sort, but we should support count sort as well, even if it's not a
    # common use case.
    def rows
      super.sort { |a, b| a.value.first <=> b.value.first }
    end

    private

    def new_row(pair)
      DateFacetRow.new(pair, @gap, self)
    end
  end
end
