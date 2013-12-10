module Sunspot
  module DSL
    class FieldStats #:nodoc:
      def initialize(query_stats, setup, search_stats) #:nodoc:
        @query_stats, @setup, @search_stats = query_stats, setup, search_stats
      end

      def facet *field_names
        field_names.each do |field_name|
          field = @setup.field(field_name)

          @query_stats.add_facet(field)
          @search_stats.add_facet(field)
        end
      end
    end
  end
end
