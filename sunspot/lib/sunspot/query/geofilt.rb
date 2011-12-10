module Sunspot
  module Query
    class Geofilt
      def initialize(field, lat, lon, radius)
        @field, @lat, @lon, @radius = field, lat, lon, radius
      end

      def to_params
        filter = "{!geofilt sfield=#{@field.indexed_name} pt=#{@lat},#{@lon} d=#{@radius}}"

        {:fq => filter}
      end
    end
  end
end
