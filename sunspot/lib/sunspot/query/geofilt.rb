module Sunspot
  module Query
    class Geofilt < Restriction::Base
      def initialize(field, lat, lon, radius, options = {})
        @field, @lat, @lon, @radius, @options = field, lat, lon, radius, options
      end

      def to_params
        {:fq => to_solr_conditional}
      end

      def to_solr_conditional
        if tagged?
          "{!tag=#{tag}}_query_:\"#{geo_phrase}\""
        else
          geo_phrase
        end
      end

      def geo_phrase
        func = @options[:bbox] ? "bbox" : "geofilt"
        "{!#{func} sfield=#{@field.indexed_name} pt=#{@lat},#{@lon} d=#{@radius}}"
      end
    end
  end
end
