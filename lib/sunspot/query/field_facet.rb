module Sunspot
  module Query
    class FieldFacet < AbstractFieldFacet
      def to_params
        super.merge(:"facet.field" => [@field.indexed_name])
      end
    end
  end
end
