module Sunspot
  # 
  # Objects of this class encapsulate a single query facet row returned for a
  # query facet.
  #
  class QueryFacetRow
    #
    # This is the "label" passed into the query facet row when it is defined in
    # the search.
    #
    attr_reader :value
    # 
    # Number of documents in the result set that match this facet's scope.
    #
    attr_reader :count

    def initialize(value, count) #:nodoc:
      @value, @count = value, count
    end
  end
end
