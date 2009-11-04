module Sunspot
  module Query
    class DateFieldFacet < AbstractFieldFacet
      def to_params
        params = super
        params[:"facet.date"] = [@field.indexed_name]
        params[qualified_param('date.start')] = @field.to_indexed(@options[:time_range].first)
        params[qualified_param('date.end')] = @field.to_indexed(@options[:time_range].last)
        params[qualified_param('date.gap')] = "+#{@options[:time_interval] || 86400}SECONDS"
        params
      end
    end
  end
end
