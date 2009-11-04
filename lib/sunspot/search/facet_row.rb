module Sunspot
  class Search
    class FacetRow
      attr_reader :value, :count
      attr_writer :instance #:nodoc:

      def initialize(value, count, facet)
        @value, @count, @facet = value, count, facet
      end

      def instance
        if !defined?(@instance)
          @facet.populate_instances
        end
        @instance
      end

      def inspect
        "<Sunspot::Search::FacetRow:#{value.inspect} (#{count})>"
      end
    end
  end
end
