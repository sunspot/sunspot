module Sunspot
  module Search
    class DateFacet
      def initialize(field, search, options)
        @field, @search, @options = field, search, options
      end

      def field_name
        @field.name
      end

      def rows
        @rows ||=
          begin
            data = @search.facet_response['facet_dates'][@field.indexed_name]
            gap = (@options[:time_interval] || 86400).to_i
            rows = []
            data.each_pair do |value, count|
              if value =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/
                start_time = @field.cast(value)
                end_time = start_time + gap
                rows << FacetRow.new(start_time..end_time, count, self)
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
