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
        super.merge(:"facet.field" => [tagged_field_name])
      end

      private

      def tagged_field_name
        if @exclude_tag
          "{!ex=#{@exclude_tag}}#{@field.indexed_name}"
        else
          @field.indexed_name
        end
      end 
    end
  end
end
