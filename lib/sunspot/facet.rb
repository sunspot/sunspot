module Sunspot
  class Facet
    attr_reader :field

    def initialize(facet_values, field)
      @facet_values, @field = facet_values, field
    end

    def rows
      @rows ||=
        @facet_values.map do |facet_value|
          FacetRow.new(facet_value, self)
        end
    end
  end
end
