module Sunspot
  module Search
    class StatsFacet
      def initialize(field, data) #:nodoc:
        @field, @data = field, data
      end

      def rows
        @rows ||= @data.map { |value, data| StatsRow.new(@field, data, value) }
      end
    end
  end
end
