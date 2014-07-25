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

      def add_disjunction
        @components << disjunction = Disjunction.new
        disjunction
      end

      def add_conjunction
        @components << conjunction = Conjunction.new
        conjunction
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

      def to_subquery
        "(#{@components.map(&:to_subquery).join(" #{connector} ")})"
      end

      private

      attr_reader :components

      def to_subqueries
        { :q => to_subquery }
      end
    end

    class Disjunction < CompositeFulltext
      #
      # No-op - this is already a disjunction
      #
      def add_disjunction
        self
      end

      private

      def connector
        'OR'
      end
    end

    class Conjunction < CompositeFulltext
      #
      # No-op - this is already a conjunction
      #
      def add_conjunction
        self
      end

      private

      def connector
        'AND'
      end
    end
  end
end
