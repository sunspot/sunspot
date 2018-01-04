module Sunspot
  module Query
    class FieldJsonFacet < AbstractFieldFacet

      def initialize(field, options)
        @field, @options = field, options
        super
      end

      def to_params
        super.merge(:"json.facet" => field_name_with_local_params.to_json)
      end

      def field_name_with_local_params
        { count: @field.indexed_name }
      end
    end
  end
end
