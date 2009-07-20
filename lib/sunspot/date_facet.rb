module Sunspot
  #
  # Date facets are retrieved by passing a :time_range key into the
  # DSL::FieldQuery#facet options. They are only available for Date and Time
  # type fields. The #value for date facet rows is a Range object encapsulating
  # the time range covered by the row.
  #
  class DateFacet < Facet
    def initialize(facet_values, field) #:nodoc:
      @gap = facet_values.delete('gap')[/\+(\d+)SECONDS/,1].to_i
      %w(start end).each { |key| facet_values.delete(key) }
      super(facet_values.to_a.flatten, field)
    end

    #
    # Get the rows of this date facet, which are instances of DateFacetRow.
    # The rows will always be sorted in chronological order.
    #
    #--
    #
    # The date facet info comes back from Solr as a hash, so we need to sort
    # it manually. FIXME this currently assumes we want to do a "lexical"
    # sort, but we should support count sort as well, even if it's not a
    # common use case.
    #
    def rows
      super.sort { |a, b| a.value.first <=> b.value.first }
    end

    private

    def new_row(pair)
      DateFacetRow.new(pair, @gap, self)
    end
  end
end
