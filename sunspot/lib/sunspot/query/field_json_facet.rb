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

      def field_name_with_local_params(stats_field = nil)
        if !stats_field.nil?
          {
            @field.name => {
              type: 'terms',
              field: @field.indexed_name,
              facet: {
                min: "min(#{stats_field.indexed_name})",
                max: "max(#{stats_field.indexed_name})",
                sum: "sum(#{stats_field.indexed_name})",
                avg: "avg(#{stats_field.indexed_name})",
                sumsq: "sumsq(#{stats_field.indexed_name})",
              }
            }
          }
        else
          { count: @field.indexed_name }
        end
      end
    end
  end
end
