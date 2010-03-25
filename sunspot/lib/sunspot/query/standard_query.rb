module Sunspot
  module Query
    class StandardQuery < CommonQuery
      attr_accessor :scope, :fulltext

      def initialize(types)
        super
        @components << @fulltext = CompositeFulltext.new
      end

      def add_fulltext(keywords)
        @fulltext.add(keywords)
      end

      def add_location_restriction(coordinates, radius)
        @components << @local = Local.new(coordinates, radius)
      end
    end
  end
end
