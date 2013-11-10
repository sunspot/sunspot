module Sunspot
  module Search
    class StatsFacet < FieldFacet
      def initialize(field, data) #:nodoc:
        @field, @data = field, data
      end

      def rows(options = {})
        if options[:verified]
          verified_rows
        else
          @rows ||= @data.map do |value, data|
            StatsRow.new(data, self, @field.type.cast(value))
          end
        end
      end

      def inspect
        "<Sunspot::Search::StatsFacet:#{@field}>"
      end
    end
  end
end
