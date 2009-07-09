module Sunspot
  #TODO document
  class DateFacetRow < FacetRow
    def initialize(pair, gap, facet)
      @gap = gap
      super(pair, facet)
    end

    def value
      @value ||=
        begin
          start_date = @facet.field.cast(@pair[0])
          Range.new(start_date, start_date + @gap)
        end
    end
  end
end
