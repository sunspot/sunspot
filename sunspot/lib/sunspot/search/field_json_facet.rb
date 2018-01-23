module Sunspot
  module Search
    class FieldJsonFacet

      attr_reader :name

      def initialize(field, search, options)
        @name, @search, @options = name, search, options
        @field = field
      end

      def rows
        @rows ||=
          begin
            json_facet_response = @search.json_facet_response[@field.name.to_s]
            data = json_facet_response.nil? ? [] : json_facet_response['buckets']
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
    end
  end
end
