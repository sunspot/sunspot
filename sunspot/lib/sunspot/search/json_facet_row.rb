module Sunspot
  module Search
    class JsonFacetRow
      attr_reader :value, :count, :nested
      attr_writer :instance #:nodoc:

      def initialize(data, facet) #:nodoc:
        @value = data['val']
        @count = data['distinct'] || data['count']
        @facet = facet
        @nested_key = data.keys.select { |k| data[k].is_a?(Hash) }.first
        @nested = recursive_nested_initialization(data) unless @nested_key.nil?
      end

      # 
      # Return the instance referenced by this facet row. Only valid for field
      # facets whose fields are defined with the :references key.
      #
      def instance
        if !defined?(@instance)
          @facet.populate_instances
        end
        @instance
      end

      def inspect
        "<Sunspot::Search::FacetRow:#{value.inspect} (#{count}) #{nested.nil? ? '' : " nested_count=#{nested.size}"}>"
      end

      private

      def recursive_nested_initialization(data)
        data[@nested_key]['buckets'].map do |d|
          JsonFacetRow.new(d, @facet)
        end
      end

    end
  end
end
