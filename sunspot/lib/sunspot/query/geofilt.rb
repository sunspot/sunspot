module Sunspot
  module Query
    class Geofilt
      include Filter
      attr_reader :field

      def initialize(field, lat, lon, radius, options = {})
        @field, @lat, @lon, @radius, @options = field, lat, lon, radius, options
      end

      def to_boolean_phrase
        func = @options[:bbox] ? "bbox" : "geofilt"
        "{!#{func} sfield=#{@field.indexed_name} pt=#{@lat},#{@lon} d=#{@radius}}"
      end

      def to_params
        {:fq => to_filter_query}
      end
    end
  end
end
