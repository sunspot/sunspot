module Sunspot
  module Query
    class StandardQuery < CommonQuery
      attr_accessor :scope, :fulltext

      def initialize(types)
        super
        @components << @fulltext = Conjunction.new
      end

      def add_fulltext(keywords)
        @fulltext.add_fulltext(keywords)
      end

      def add_join(keywords, target, from, to)
        @fulltext.add_join(keywords, target, from, to)
      end

      def add_boost_query(factor)
        @fulltext.add_boost_query(factor)
      end

      def add_boost_function(function)
        @fulltext.add_boost_function(function)
      end

      def add_multiplicative_boost_function(function)
        @fulltext.add_multiplicative_boost_function(function)
      end

      def disjunction
        parent_fulltext = @fulltext
        @fulltext = @fulltext.add_disjunction

        yield
      ensure
        @fulltext = parent_fulltext
      end

      def conjunction
        parent_fulltext = @fulltext
        @fulltext = @fulltext.add_conjunction

        yield
      ensure
        @fulltext = parent_fulltext
      end
    end
  end
end
