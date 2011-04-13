module Sunspot
  module Search
    class FacetRow
      attr_reader :value, :count, :selected
      attr_writer :instance #:nodoc:

      def initialize(value, count, selected, facet) #:nodoc:
        @value, @count, @selected, @facet = value, count, selected, facet
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
        "<Sunspot::Search::FacetRow:#{value.inspect} (#{count})>"
      end
    end
  end
end
