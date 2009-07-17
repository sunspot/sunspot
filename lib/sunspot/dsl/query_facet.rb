module Sunspot
  module DSL
    class QueryFacet
      def initialize(query_facet)
        @query_facet = query_facet
      end

      def row(label, &block)
        Scope.new(@query_facet.add_row(label)).instance_eval(&block)
      end
    end
  end
end
