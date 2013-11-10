module Sunspot
  module Search
    class StatsRow
      attr_reader :data, :value

      def initialize(field, data, value, facet_fields = []) #:nodoc:
        @field, @data, @value, @facet_fields = field, data, value, facet_fields
      end

      def min
        data['min']
      end

      def max
        data['max']
      end

      def count
        data['count']
      end

      def sum
        data['sum']
      end

      def missing
        data['missing']
      end

      def sum_of_squares
        data['sumOfSquares']
      end

      def mean
        data['mean']
      end

      def standard_deviation
        data['stddev']
      end

      def facet name
        facets[name.to_sym]
      end

      def facets
        @facets ||= @facet_fields.each_with_object({}) do |field, hash|
          hash[field.name] = StatsFacet.new(
            field, data['facets'][field.indexed_name]
          )
        end
      end

      def inspect
        "<Sunspot::Search::StatsRow:#{value.inspect} min=#{min} max=#{max} count=#{count}>"
      end
    end
  end
end
