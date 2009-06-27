module Sunspot
  class Query
    # 
    # The Sort class is a query component representing a sort by a given field.
    # 
    class Sort #:nodoc:
      DIRECTIONS = {
        :asc => 'asc',
        :ascending => 'asc',
        :desc => 'desc',
        :descending => 'desc'
      }

      def initialize(field, direction = nil)
        @field, @direction = field, (direction || :asc).to_sym
      end

      def to_param
        "#{@field.indexed_name.to_sym} #{direction_for_solr}"
      end

      private

      def direction_for_solr
        DIRECTIONS[@direction] || 
          raise(
            ArgumentError,
            "Unknown sort direction #{@direction}. Acceptable input is: #{DIRECTIONS.keys.map { |input| input.inspect } * ', '}"
        )
      end
    end
  end
end
