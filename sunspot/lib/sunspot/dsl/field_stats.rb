module Sunspot
  module DSL
    class FieldStats #:nodoc:
      include BlockJoin
      include BlockJoin::JsonFaceting

      def initialize(query_stats, setup, search_stats, scope = nil) #:nodoc:
        @query_stats, @setup, @search_stats = query_stats, setup, search_stats
        @scope = scope # For block-join faceting stats!
      end

      def facet *field_names
        field_names.each do |field_name|
          field = @setup.field(field_name)

          @query_stats.add_facet(field)
          @search_stats.add_facet(field)
        end
      end

      def json_facet(field_name, options = {})
        facet = Sunspot::Util.parse_json_facet(field_name, options, @setup)
        @query_stats.add_json_facet(facet)
      end
    end
  end
end
