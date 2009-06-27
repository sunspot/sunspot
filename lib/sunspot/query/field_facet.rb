module Sunspot
  class Query
    #
    # Encapsulates a query component representing a field facet. Users create
    # instances using DSL::Query#facet
    #
    class FieldFacet #:nodoc:
      def initialize(field)
        @field = field
      end

      # ==== Returns
      #
      # Hash:: solr-ruby params for this field facet
      #
      def to_params
        { :"facet.field" => [@field.indexed_name], 'facet' => 'true' }
      end
    end
  end
end
