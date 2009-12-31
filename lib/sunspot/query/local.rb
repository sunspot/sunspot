module Sunspot
  module Query
    # 
    # This query component generates parameters for LocalSolr geo-radial
    # searches. The LocalSolr API is fairly rigid, so the Local component
    # doesn't have any options - it just takes coordinates and a radius, and
    # generates the appropriate parameters.
    #
    class Local #:nodoc:
      def initialize(coordinates, options)
        @coordinates, @options = Util::Coordinates.new(coordinates), options
      end

      def to_params
        local_params = [
          [:radius, @options[:distance]],
          [:sort, @options[:sort]]
        ].map do |key,value|
          "#{key}=#{value}" if value
        end.compact.join(" ") #TODO Centralized local param builder
        query = "{!#{local_params}}#{@coordinates.lat},#{@coordinates.lng}"
        { :spatial => query }
      end
    end
  end
end
