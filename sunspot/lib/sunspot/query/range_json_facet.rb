module Sunspot
  module Query
    class RangeJsonFacet < AbstractJsonFieldFacet

      def initialize(field, options, setup)
        raise Exception.new("Need to specify a range") if options[:range].nil?
        @start = options[:range].first
        @end = options[:range].last
        @gap = options[:gap] || 86400
        super
      end

      def field_name_with_local_params
        {
          @field.name => {
            type: 'range',
            field: @field.indexed_name,
            start: @field.to_indexed(@start),
            end: @field.to_indexed(@end),
            gap: @gap
          }.merge!(init_params)
        }
      end
    end
  end
end
