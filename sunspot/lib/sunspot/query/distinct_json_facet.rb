module Sunspot
  module Query
    class DistinctJsonFacet < AbstractFieldFacet

      STRATEGIES = [:unique, :hll]

      def initialize(field, options)
        raise Exception.new("Need to specify a strategy") if options[:strategy].nil?
        @stategy = STRATEGIES.include?(options[:strategy]) ? options[:strategy] : :unique
        @group = options[:group] || field
        super
      end

      def to_params
        super.merge(:"json.facet" => field_name_with_local_params.to_json)
      end

      def field_name_with_local_params
        {
          categories: {
            type: 'terms',
            field: @group.indexed_name,
            facet: {
              distinct: "#{@stategy}(#{@field.indexed_name})"
            }
          }
        }
      end
    end
  end
end
