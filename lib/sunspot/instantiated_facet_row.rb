module Sunspot
  class InstantiatedFacetRow < FacetRow
    attr_writer :instance

    def initialize(value, count, facet)
      super(value, count)
      @facet = facet
    end

    #
    # Get the persistent object referenced by this row's value. Instances are
    # batch-lazy-loaded, which means that for a given facet, all of the
    # instances are loaded the first time any row's instance is requested.
    #
    def instance
      unless defined?(@instance)
        @facet.populate_instances!
      end
      @instance
    end
  end
end
