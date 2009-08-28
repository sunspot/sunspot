module Sunspot
  # This class encapsulates a facet row (value) for a facet.
  class FacetRow
    attr_reader :value, :count

    def initialize(value, count) #:nodoc:
      @value, @count = value, count
    end
  end
end
