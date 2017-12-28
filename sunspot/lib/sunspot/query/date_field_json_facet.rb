module Sunspot
  module Query
    class DateFieldJsonFacet < AbstractFieldFacet

      def initialize(field, options)
        raise Exception.new("Need to specify a time_range") if options[:time_range].nil?
        @start = options[:time_range].first
        @end = options[:time_range].last
        @gap = "+#{options[:gap] || 86400}SECONDS"
        super
      end

      def to_params
        super.merge(:"json.facet" => field_name_with_local_params.to_json)
      end

      def field_name_with_local_params(stats_field = nil)
        if !stats_field.nil?
          {
            @field.name => {
              type: 'range',
              field: @field.indexed_name,
              start: @field.to_indexed(@start),
              end: @field.to_indexed(@end),
              gap: @gap,
              facet: {
                min: "min(#{stats_field.indexed_name})",
                max: "max(#{stats_field.indexed_name})",
                sum: "sum(#{stats_field.indexed_name})",
                avg: "avg(#{stats_field.indexed_name})"
              }
            }
          }
        else
          {
            @field.name => {
              type: 'range',
              field: @field.indexed_name,
              start: @field.to_indexed(@start),
              end: @field.to_indexed(@end),
              gap: @gap
            }
          }
        end
      end
    end
  end
end
