module Sunspot
  module Query
    # 
    # Representation of a BoostQuery, which allows the searcher to specify a
    # scope for which matching documents should have an extra boost. This is
    # essentially a conjunction, with an extra instance variable containing
    # the boost that should be applied.
    #
    class BoostQuery < Connective::Conjunction #:nodoc:
      def initialize(boost)
        super(false)
        @boost = boost
      end

      def to_boolean_phrase
        if @boost.is_a?(FunctionQuery)
          "#{@boost}"
        else
          "#{super}^#{@boost}"
        end
      end
    end
  end
end
