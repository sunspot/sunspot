module Sunspot
  module Search
    class FacetRow
      attr_reader :value, :count
      attr_writer :instance #:nodoc:

      def initialize(value, count, facet) #:nodoc:
        @value, @count, @facet = value, count, facet
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
