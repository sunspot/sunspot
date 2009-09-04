module Sunspot
  class Facet
    def initialize(facet_data) #:nodoc:
      @facet_data = facet_data
    end

    # 
    # For field facets, this is the field name. For query facets, this is the
    # name given to the #facet method in the DSL.
    #
    def name
      @facet_data.name
    end
    alias_method :field_name, :name

    # 
    # Collection of FacetRow objects containing the individual values returned
    # by the facet.
    #
    def rows
      @facet_data.rows { |value, count| FacetRow.new(value, count) }
    end
  end
end
