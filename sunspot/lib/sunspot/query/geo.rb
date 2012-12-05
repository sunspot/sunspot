begin
  require 'geohash'
rescue LoadError
  require 'pr_geohash'
end

module Sunspot
  module Query
    class Geo
      MAX_PRECISION = 12
      DEFAULT_PRECISION = 7
      DEFAULT_PRECISION_FACTOR = 16.0

      def initialize(field, lat, lng, options)
        @field, @options = field, options
        @geohash = GeoHash.encode(lat.to_f, lng.to_f, MAX_PRECISION)
      end

      def to_params
        { :q => to_boolean_query }
      end

      def to_subquery
        "(#{to_boolean_query})"
      end

      private

      def to_boolean_query
        queries = []
        MAX_PRECISION.downto(precision) do |i|
          star = i == MAX_PRECISION ? '' : '*'
          precision_boost = Util.format_float(
            boost * precision_factor ** (i-MAX_PRECISION).to_f, 3)
          queries << "#{@field.indexed_name}:#{@geohash[0, i]}#{star}^#{precision_boost}"
        end
        queries.join(' OR ')
      end

      def precision
        @options[:precision] || DEFAULT_PRECISION
      end

      def precision_factor
        @options[:precision_factor] || DEFAULT_PRECISION_FACTOR
      end

      def boost
        @options[:boost] || 1.0
      end
    end
  end
end
