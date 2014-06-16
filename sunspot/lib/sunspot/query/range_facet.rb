module Sunspot
  module Query

    class RangeFacet < AbstractFieldFacet
      def initialize(field, options)
        if exclude_filters = options[:exclude]
          @exclude_tag = Util.Array(exclude_filters).map do |filter|
            filter.tag
          end.join(',')
        end
        super
      end

      def to_params
        params = super
        params[:"facet.range"] = [field_name_with_local_params]
        params[qualified_param('range.start')] = @field.to_indexed(@options[:range].first)
        params[qualified_param('range.end')] = @field.to_indexed(@options[:range].last)
        params[qualified_param('range.gap')] = "#{@options[:range_interval] || 10}"
        params[qualified_param('range.include')] = @options[:include].to_s if @options[:include]
        params
      end

      private

      def local_params
        @local_params ||=
          begin
            local_params = {}
            local_params[:ex] = @exclude_tag if @exclude_tag
            local_params[:key] = @options[:name] if @options[:name]
            local_params
          end
      end

      def field_name_with_local_params
        if local_params.empty?
          @field.indexed_name
        else
          pairs = local_params.map do |key, value|
            "#{key}=#{value}"
          end
          "{!#{pairs.join(' ')}}#{@field.indexed_name}"
        end
      end
    end

  end
end
