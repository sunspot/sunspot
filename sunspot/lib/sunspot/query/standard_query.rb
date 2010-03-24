module Sunspot
  module Query
    class StandardQuery < CommonQuery
      attr_accessor :scope, :fulltext

      def set_fulltext(keywords)
        @components << @fulltext = Dismax.new(keywords)
        @fulltext
      end

      def add_location_restriction(coordinates, radius)
        @components << @local = Local.new(coordinates, radius)
      end
    end
  end
end
