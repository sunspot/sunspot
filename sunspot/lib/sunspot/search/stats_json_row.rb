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
        !data['min'].nil? ? data['min'] : 0
      end

      def max
        !data['max'].nil? ? data['max'] : 0
      end

      def count
        !data['count'].nil? ? data['count'] : 0
      end

      def sum
        !data['sum'].nil? ? data['sum'] : 0
      end

      def missing
        !data['missing'].nil? ? data['missing'] : 0
      end

      def sumsq
        sum_of_squares
      end

      def sum_of_squares
        !data['sumsq'].nil? ? data['sumsq']: 0
      end

      def avg
        mean
      end

      def mean
        !data['avg'].nil? ? data['avg'] : 0
      end

      def standard_deviation
        !data['stddev'].nil? ? data['stddev'] : 0
      end

      def facet name
        facets.find { |facet| facet.field.name == name.to_sym }
      end

      def facets
        @facets ||= @facet_fields.map do |field|
          StatsFacet.new(field, !data.nil? ? data['facets'][field.indexed_name] : [])
        end
      end

      def instance
        if !defined?(@instance)
          @facet.populate_instances
        end
        @instance
      end

      def inspect
        "<Sunspot::Search::StatsJsonRow:#{value.inspect} min=#{min} max=#{max} count=#{count} sum=#{sum} missing=#{missing} sum_of_squares=#{sum_of_squares} mean=#{mean} standard_deviation=#{standard_deviation} #{nested.nil? ? '' : " nested_count=#{nested.size}"}>"
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
