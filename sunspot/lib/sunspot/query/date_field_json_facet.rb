module Sunspot
  module Query
    class DateFieldJsonFacet < AbstractJsonFieldFacet

      def initialize(field, options, setup)
        raise Exception.new('Need to specify a time_range') if options[:time_range].nil?
        @start = options[:time_range].first
        @end = options[:time_range].last
        @gap = "+#{options[:gap] || 86400}SECONDS"
        super
      end

      def field_name_with_local_params
        params = {}
        params[:type] = 'range'
        params[:field] = @field.indexed_name
        params[:start] = @field.to_indexed(@start)
        params[:end] = @field.to_indexed(@end)
        params[:gap] = @gap
        params.merge!(init_params)
        { @field.name => params }
      end
    end
  end
end
