module Sunspot
  module Search
    class StatsFacet < FieldFacet
      attr_reader :field

      def initialize(field, data) #:nodoc:
        @field, @data = field, data
      end

      def rows(options = {})
        if options[:verified]
          verified_rows
        else
          @rows ||= @data.map do |value, data|
            StatsRow.new(data, self, @field.type.cast(value))
          end.sort_by { |row| row.value.to_s }
        end
      end

      def inspect
        "<Sunspot::Search::StatsFacet:#{@field}>"
      end
    end
  end
end
