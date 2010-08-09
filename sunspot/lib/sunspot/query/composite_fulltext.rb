module Sunspot
  module Query
    class CompositeFulltext
      def initialize
        @components = []
      end

      def add(keywords)
        @components << dismax = Dismax.new(keywords)
        dismax
      end
      
      def add_location(field, lat, lng, options)
        @components << location = Geo.new(field, lat, lng, options)
        location
      end

      def to_params
        case @components.length
        when 0
          {}
        when 1
          @components.first.to_params.merge(:fl => '* score')
        else
          to_subqueries.merge(:fl => '* score')
        end
      end

      private

      def to_subqueries
        { :q => @components.map { |dismax| dismax.to_subquery }.join(' ') }
      end
    end
  end
end
