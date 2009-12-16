module Sunspot
  module Query
    class FieldFacet < AbstractFieldFacet
      def initialize(field, options)
        if exclude_filters = options[:exclude]
          @exclude_tag = Util.Array(exclude_filters).map do |filter|
            filter.tag
          end.join(',')
        end
        super
      end

      def to_params
        super.merge(:"facet.field" => [field_name_with_local_params])
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
