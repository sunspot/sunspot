module Sunspot
  module Search
    class JsonFacetStats
      def initialize(field, search, options)
        @field, @search, @options = field, search, options
      end

      def rows
        @rows ||=
          begin
            json_facet_response = @search.json_facet_response[@field.to_s]
            data = json_facet_response.nil? ? [] : json_facet_response['buckets']
            rows = []
            data.each do |d|
              rows << StatsJsonRow.new(d, nil, d['val'])
            end
            rows
          end

      end
    end
  end
end
