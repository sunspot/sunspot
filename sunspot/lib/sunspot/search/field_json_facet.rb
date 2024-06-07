module Sunspot
  module Search
    class FieldJsonFacet

      attr_reader :name

      def initialize(field, search, options)
        @name, @search, @options = (options[:name] || field.name), search, options
        @field = field
      end

      def rows
        @rows ||=
          begin
            data = no_data? ? [] : @search.json_facet_response[@field.name.to_s]['buckets']
            rows = []
            data.each do |d|
              rows << JsonFacetRow.new(d, self)
            end

            if @options[:sort] == :count
              rows.sort! { |lrow, rrow| rrow.count <=> lrow.count }
            else
              rows.sort! { |lrow, rrow| lrow.value <=> rrow.value }
            end
            rows
          end

      end

      def no_data?
        @search.json_facet_response[@field.name.to_s].nil?
      end

      def other_count(type)
        json_facet_for_field = @search.json_facet_response[@field.name.to_s]
        return 0 if json_facet_for_field.nil?

        other = json_facet_for_field[type.to_s] || {}
        other['count']
      end
    end
  end
end
