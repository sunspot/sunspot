module Sunspot
  module Query
    class RangeFacet < AbstractFieldFacet
      def to_params
        params = super
        params[:"facet.range"] = [@field.indexed_name]
        params[qualified_param('range.start')] = @field.to_indexed(@options[:range].first)
        params[qualified_param('range.end')] = @field.to_indexed(@options[:range].last)
        params[qualified_param('range.gap')] = "#{@options[:range_interval] || 10}"
        params
      end
    end
  end
end
