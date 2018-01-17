module Sunspot
  module Search
    class StatJsonFacet
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
              rows << StatsRow.new(d, nil, d['val'])
            end
            if @options[:sort] == :index
              rows.sort! { |lrow, rrow| lrow.value <=> rrow.value }
            else
              rows.sort! { |lrow, rrow| lrow.count <=> rrow.count }
            end
            rows
          end

      end
    end
  end
end
