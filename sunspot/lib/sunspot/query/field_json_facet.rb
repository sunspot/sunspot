module Sunspot
  module Query
    class FieldJsonFacet < AbstractJsonFieldFacet

      def initialize(field, options, setup)
        super
      end

      def field_name_with_local_params
        {
          @field.name => {
            type: 'terms',
            field: @field.indexed_name,
          }.merge!(init_params)
        }
      end
    end
  end
end
