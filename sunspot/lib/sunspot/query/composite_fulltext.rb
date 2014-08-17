module Sunspot
  module Query
    class CompositeFulltext
      def initialize
        @components = []
      end

      def add_fulltext(keywords)
        @components << dismax = Dismax.new(keywords)
        dismax
      end

      def add_join(keywords, target, from, to)
        @components << join = Join.new(keywords, target, from, to)
        join
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
        if @components.length == 0
          {}
        elsif @components.length > 1 or @components.find { |c| c.is_a?(Join) }
          to_subquery.merge(:fl => '* score')
        else
          @components.first.to_params.merge(:fl => '* score')
        end
      end

      def to_subquery
        return {} unless @components.any?

        params = @components.map(&:to_subquery).inject({:q => []}) do |res, subquery|
          res[:q] << subquery.delete(:q) if subquery[:q]
          res.merge(subquery)
        end

        params[:q] = params[:q].size > 1 ? "(#{params[:q].join(" #{connector} ")})" : params[:q].join
        params
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
