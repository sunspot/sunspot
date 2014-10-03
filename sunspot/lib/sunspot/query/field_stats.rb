module Sunspot
  module Query
    class FieldStats
      def initialize(field, options)
        @field, @options = field, options
        @facets = []
      end

      def add_facet field
        @facets << field
      end

      def to_params
        params = { :stats => true, :"stats.field" => [@field.indexed_name]}
        params[facet_key] = @facets.map(&:indexed_name) unless @facets.empty?
        params
      end

      def facet_key
        qualified_param 'facet'
      end

      def qualified_param name
        :"f.#{@field.indexed_name}.stats.#{name}"
      end
    end
  end
end
