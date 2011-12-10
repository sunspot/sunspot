module Sunspot
  module Query
    class Spatial
      def initialize(field, lat, lon, options)
        @field, @lat, @lon, @options = field, lat, lon, options
      end

      # TODO: I don't necessarily think sorting by geodist() should be
      # the default. Let's pull this out and support something like 
      # order_by(:geodist)
      def to_params
        {:sfield => @field.indexed_name,
         :fq     => "{!geofilt}",
         :pt     => "#{@lat},#{@lon}",
         :sort   => "geodist() asc"}.tap do |params|
          params[:d] = @options[:radius] if @options[:radius]
        end
      end

    end
  end
end
