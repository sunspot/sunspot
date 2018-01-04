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

      def add_json_facet(json_facet)
        @json_facet = json_facet
      end

      def to_params
        params = {}
        if !@json_facet.nil?
          params.merge!(:"json.facet" => @json_facet.field_name_with_local_params(@field))
        else
          params.merge!({:stats => true, :"stats.field" => [@field.indexed_name]})
          params[facet_key] = @facets.map(&:indexed_name) unless @facets.empty?
        end
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
