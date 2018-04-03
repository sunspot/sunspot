module Sunspot
  module Search
    class StatsJsonRow
      attr_reader :data, :value, :nested
      attr_writer :instance #:nodoc:

      def initialize(data, facet = nil, value = nil) #:nodoc:
        @data, @facet, @value = data, facet, value
        @facet_fields = []
        @nested_key = data.keys.select { |k| data[k].is_a?(Hash) }.first
        @nested = recursive_nested_initialization(data) unless @nested_key.nil?
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
        data['sumsq']
      end
      alias :sumsq :sum_of_squares

      def mean
        data['avg']
      end
      alias :avg :mean

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
        "<Sunspot::Search::StatsJsonRow:#{value.inspect} min=#{min} max=#{max}"\
        " count=#{count} sum=#{sum} missing=#{missing} sum_of_squares=#{sum_of_squares}"\
        " mean=#{mean} standard_deviation=#{standard_deviation}"\
        " #{nested.nil? ? '' : "nested_count=#{nested.size}"}>"
      end

      private

      def recursive_nested_initialization(data)
        data[@nested_key]['buckets'].map do |d|
          StatsJsonRow.new(d, @facet, d['val'])
        end
      end

    end
  end
end
