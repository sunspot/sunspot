module Sunspot
  class QueryFacetRow
    attr_reader :value, :count

    def initialize(value, count)
      @value, @count = value, count
    end
  end
end
