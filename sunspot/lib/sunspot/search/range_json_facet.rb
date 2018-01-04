module Sunspot
  module Search
    class RangeJsonFacet
      def initialize(field, search, options)
        @field, @search, @options = field, search, options
      end

      def rows
        @rows ||=
          begin
            json_facet_response = @search.json_facet_response[@field.name.to_s]
            data = json_facet_response.nil? ? [] : json_facet_response['buckets']
            rows = []
            data.each do |d|
              rows << FacetRow.new(d['val'], d['count'], self)
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