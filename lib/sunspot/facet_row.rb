module Sunspot
  class FacetRow
    def initialize(facet_value, facet)
      @facet_value, @facet = facet_value, facet
    end

    def value
      @value ||= @facet.field.cast(@facet_value.name)
    end

    def count
      @count ||= @facet_value.value
    end
  end
end
