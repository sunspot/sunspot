module Sunspot
  module Search
    class RangeFacet
      def initialize(field, search, options)
        @field, @search, @options = field, search, options
      end

      def field_name
        @field.name
      end

      def rows
        @rows ||=
          begin
            data = @search.facet_response['facet_ranges'][@field.indexed_name]
            gap = (@options[:range_interval] || 10).to_i
            rows = []
            
            if data['counts']
              Hash[*data['counts']].each_pair do |start_str, count|
                start = start_str.to_f
                finish = start + gap
                rows << FacetRow.new(start..finish, count, self)
              end
            end

            if @options[:sort] == :count
              rows.sort! { |lrow, rrow| rrow.count <=> lrow.count }
            else
              rows.sort! { |lrow, rrow| lrow.value.first <=> rrow.value.first }
            end
            rows
          end
      end
    end
  end
end
