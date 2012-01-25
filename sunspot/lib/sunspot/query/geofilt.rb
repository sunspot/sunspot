module Sunspot
  module Query
    class Geofilt
      def initialize(field, lat, lon, radius, options = {})
        @field, @lat, @lon, @radius, @options = field, lat, lon, radius, options
      end

      def to_params
        func = @options[:bbox] ? "bbox" : "geofilt"

        filter = "{!#{func} sfield=#{@field.indexed_name} pt=#{@lat},#{@lon} d=#{@radius}}"
        {:fq => filter}
      end
    end
  end
end
