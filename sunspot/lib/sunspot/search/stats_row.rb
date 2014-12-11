module Sunspot
  module Search
    class StatsRow
      attr_reader :data, :value
      attr_writer :instance #:nodoc:

      def initialize(data, facet = nil, value = nil) #:nodoc:
        @data, @facet, @value = data, facet, value
        @facet_fields = []
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
        facets.find { |facet| facet.field.name == name.to_sym }
      end

      def facets
        @facets ||= @facet_fields.map do |field|
          StatsFacet.new(field, data['facets'][field.indexed_name])
        end
      end

      def instance
        if !defined?(@instance)
          @facet.populate_instances
        end
        @instance
      end

      def inspect
        "<Sunspot::Search::StatsRow:#{value.inspect} min=#{min} max=#{max} count=#{count}>"
      end
    end
  end
end
