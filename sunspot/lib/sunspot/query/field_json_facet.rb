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
        params = {}
        params[:limit] = @options[:limit] unless @options[:limit].nil?
        params[:mincount] = @options[:minimum_count] unless @options[:minimum_count].nil?
        params[:sort] = { @options[:sort] => @options[:sort_type]||'desc' } unless @options[:sort].nil?
        params[:prefix] = @options[:prefix] unless @options[:prefix].nil?
        params[:offset] = @options[:offset] unless @options[:offset].nil?

        query = {}
        query[@field.name] = {
            type: 'terms',
            field: @field.indexed_name,
          }.merge(params)

        if !stats_field.nil?
          query[@field.name].merge!(
            facet: {
              min: "min(#{stats_field.indexed_name})",
              max: "max(#{stats_field.indexed_name})",
              sum: "sum(#{stats_field.indexed_name})",
              avg: "avg(#{stats_field.indexed_name})",
              sumsq: "sumsq(#{stats_field.indexed_name})",
            })
        end
        query
      end
    end
  end
end
