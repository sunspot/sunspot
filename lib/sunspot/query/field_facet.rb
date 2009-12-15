module Sunspot
  module Query
    class FieldFacet < AbstractFieldFacet
      def initialize(field, options)
        if exclude_filter = options[:exclude]
          @exclude_tag = options[:exclude].tag
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
