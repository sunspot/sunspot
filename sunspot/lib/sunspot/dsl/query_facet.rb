module Sunspot
  module DSL
    # 
    # This tiny DSL class implements the DSL for the FieldQuery.facet
    # method.
    #
    class QueryFacet
      def initialize(query, setup, facet, options) #:nodoc:
        @query, @setup, @facet, @options = query, setup, facet, options
      end

      # 
      # Add a row to this query facet. The label argument can be anything; it's
      # simply the value that's passed into the Sunspot::QueryFacetRow object
      # corresponding to the row that's created. Use whatever seems most
      # intuitive.
      #
      # The block is evaluated in the context of a Sunspot::DSL::Scope, meaning
      # any restrictions can be placed on the documents matching this facet row.
      #
      # ==== Parameters
      #
      # label<Object>::
      #   An object used to identify this facet row in the results.
      #
      def row(label, &block)
        query_facet = Sunspot::Query::QueryFacet.new(@options)
        Sunspot::Util.instance_eval_or_call(
          Scope.new(@query.add_query_facet(query_facet), @setup),
          &block
        )
        @facet.add_row(label, query_facet.to_boolean_phrase)
      end
    end
  end
end
