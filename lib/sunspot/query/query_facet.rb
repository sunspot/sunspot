module Sunspot
  module Query
    # 
    # QueryFacets encapsulate requests for Sunspot's query faceting capability.
    # They are created by the FieldQuery#add_query_facet method.
    #
    #--
    #
    # The actual concept of a QueryFacet is somewhat artificial - it provides a
    # grouping for the facet at the Sunspot level, which provides a nicer and
    # more consistent API in Sunspot; Solr does not provide any grouping for
    # query facet rows, instead returning each requested row individually, keyed
    # by the boolean phrase used in the facet query.
    #
    class QueryFacet
      attr_reader :name #:nodoc:
      attr_reader :field #:nodoc:

      def initialize(name, setup = nil) #:nodoc:
        @name = name
        @setup = setup
        @components = []
      end

      #
      # Add a QueryFacetRow to this facet. The label argument becomes the value
      # of the Sunspot::QueryFacetRow object corresponding to this query facet
      # row.
      #
      # ==== Parameters
      #
      # label<Object>::
      #   An object that will become the value of the result row. Use whatever
      #   type is most intuitive.
      #
      # ==== Returns
      #
      # QueryFacetRow:: QueryFacetRow object containing scope for this row
      #
      def add_row(label)
        @components << row = QueryFacetRow.new(label, @setup)
        row
      end

      # 
      # Express this query facet as Solr parameters
      #
      # ==== Returns
      #
      # Hash:: Solr params hash
      #
      def to_params #:nodoc:
        components = @components.map { |component| component.to_boolean_phrase }
        components = components.first if components.length == 1
        {
          :facet => 'true',
          :"facet.query" => components
        }
      end

      # 
      # Get query facet rows (used when constructing results)
      #
      # ==== Returns
      #
      # Array:: Array of QueryFacetRow objects.
      #
      def rows #:nodoc:
        @components
      end
    end
  end
end
