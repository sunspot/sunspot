module Sunspot
  module Query
    class DateFieldFacet < AbstractFieldFacet
      def to_params
        params = super
        params[:"facet.range"] = [@field.indexed_name]
        params[qualified_param('range.start')] = @field.to_indexed(@options[:time_range].first)
        params[qualified_param('range.end')] = @field.to_indexed(@options[:time_range].last)
        params[qualified_param('range.gap')] = "+#{@options[:time_interval] || 86400}SECONDS"
        params
      end
    end
  end
end
