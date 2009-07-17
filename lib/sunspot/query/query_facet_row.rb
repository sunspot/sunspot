module Sunspot
  module Query
    class QueryFacetRow < Connective::Conjunction
      attr_reader :label

      def initialize(label, setup)
        super(setup)
        @label = label
      end
    end
  end
end
