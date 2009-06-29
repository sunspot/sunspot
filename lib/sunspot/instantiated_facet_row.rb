module Sunspot
  class InstantiatedFacetRow < FacetRow
    attr_writer :instance

    def instance
      unless defined?(@instance)
        @facet.populate_instances!
      end
      @instance
    end
  end
end
