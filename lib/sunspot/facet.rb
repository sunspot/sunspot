module Sunspot
  class Facet
    def initialize(facet_data)
      @facet_data = facet_data
    end

    def name
      @facet_data.name
    end
    alias_method :field_name, :name

    def rows
      @facet_data.rows { |value, count| FacetRow.new(value, count) }
    end
  end
end
