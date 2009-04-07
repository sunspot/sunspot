module Sunspot
  module Facets
    class FieldFacet
      def initialize(field)
        @field = field
      end

      def to_params
        { :facets => { :fields => [@field.indexed_name] }}
      end
    end
  end
end
