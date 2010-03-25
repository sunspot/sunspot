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

      def to_params
        case @components.length
        when 0
          {}
        when 1
          @components.first.to_params
        else
          to_subqueries
        end
      end

      private

      def to_subqueries
        { :q => @components.map { |dismax| dismax.to_subquery }.join(' ') }
      end
    end
  end
end
