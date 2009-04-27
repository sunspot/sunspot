module Sunspot
  module Facets
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
        { :facets => { :fields => [@field.indexed_name] }}
      end
    end
  end
end
