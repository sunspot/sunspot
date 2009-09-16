module Sunspot
  # 
  # InstantiatedFacetRow objects represent a single value for an instantiated
  # facet. As well as the usual FacetRow methods, InstantedFacetRow objects
  # provide access to the persistent object referenced by the row's value.
  #
  class InstantiatedFacetRow < FacetRow
    attr_writer :instance #:nodoc:

    def initialize(value, count, facet) #:nodoc:
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
