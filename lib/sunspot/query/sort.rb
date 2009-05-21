module Sunspot
  class Query
    # 
    # The Sort class is a query component representing a sort by a given field.
    # 
    class Sort
      ASCENDING = Set.new([:asc, :ascending])
      DESCENDING = Set.new([:desc, :descending])

      def initialize(field, direction = nil)
        @field, @direction = field, (direction || :asc).to_sym
      end

      def to_params
        { :sort => [{ @field.indexed_name.to_sym => direction_for_solr }] }
      end

      private

      def direction_for_solr
        case
        when ASCENDING.include?(@direction)
          :ascending
        when DESCENDING.include?(@direction)
          :descending
        else
          raise ArgumentError,
                "Unknown sort direction #{@direction}. Acceptable input is: #{(ASCENDING + DESCENDING).map { |input| input.inspect } * ', '}"
        end
      end
    end
  end
end
