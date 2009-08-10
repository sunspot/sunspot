module Sunspot
  module Query
    class Local
      def initialize(coordinates, radius)
        @coordinates, @radius = Util::Coordinates.new(coordinates), radius
      end

      def to_params
        {
          :qt => 'geo',
          :lat => @coordinates.lat,
          :long => @coordinates.lng,
          :radius => @radius
        }
      end
    end
  end
end
