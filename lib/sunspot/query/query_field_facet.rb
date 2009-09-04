module Sunspot
  module Query
    # 
    # QueryFieldFacets are used for the "restricted field facet" feature, which
    # allows an :only parameter for field facets, specifying a set of values in
    # which the searcher is interested. Since Solr does not support this feature
    # directly in field facets, build query facets that replicate field facet
    # behavior.
    #
    class QueryFieldFacet < QueryFacet #:nodoc:
      def initialize(field, values, options)
        super(field.name, options)
        @field = field
        values.each do |value|
          add_row(value).add_component(Restriction::EqualTo.new(field, value))
        end
      end
    end
  end
end
