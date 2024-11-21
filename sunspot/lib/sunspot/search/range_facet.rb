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
        @rows ||= [].tap do |rows|
          data = @search.facet_response['facet_ranges'][@field.indexed_name]
          gap = @options[:range_interval]
          
          if data['counts']
            data['counts'].each_slice(2) do |start_str, count|
              if start_str =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/
                start = @field.cast(start_str)
                finish = Sunspot::Util::DateMathParser.new(start).evaluate(gap)
                rows << FacetRow.new(start..finish, count, self)
              else
                start = start_str.to_f
                finish = start + gap
                rows << FacetRow.new(start..finish, count, self)
              end
            end
          end

          if @options[:sort] == :count
           rows.sort! { |lrow, rrow| rrow.count <=> lrow.count }
          else
            rows.sort! { |lrow, rrow| lrow.value.first <=> rrow.value.first }
          end
        end
      end
    end
  end
end
