module Sunspot
  module Search
    class StatsFacet
      def initialize(field, data) #:nodoc:
        @field, @data = field, data
      end

      def rows
        @rows ||= @data.each_with_object({}) do |(value, data), hash|
          hash[value] = StatsRow.new(@field, data)
        end
      end
    end
  end
end
