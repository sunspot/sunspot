module Sunspot
  module Query
    # 
    # QueryFacetRow objects encapsulate restrictions for a particular
    # QueryFacet. They also contain a label attribute, which is used as the
    # value for the search result's corresponding facet row object.
    #
    # See Query::Scope for the API provided.
    #
    class QueryFacetRow < Connective::Conjunction
      attr_reader :label #:nodoc:

      def initialize(label, setup) #:nodoc:
        super(setup)
        @label = label
      end
    end
  end
end
