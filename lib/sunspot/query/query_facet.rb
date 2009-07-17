module Sunspot
  module Query
    class QueryFacet
      attr_reader :name

      def initialize(name, setup)
        @name = name
        @setup = setup
        @components = []
      end

      def add_row(label)
        @components << row = QueryFacetRow.new(label, @setup)
        row
      end

      def to_params
        components = @components.map { |component| component.to_boolean_phrase }
        components = components.first if components.length == 1
        {
          :facet => 'true',
          :"facet.query" => components
        }
      end

      def rows
        @components
      end
    end
  end
end
