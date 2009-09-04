module Sunspot
  module Query
    # 
    # Representation of a BoostQuery, which allows the searcher to specify a
    # scope for which matching documents should have an extra boost. This is
    # essentially a conjunction, with an extra instance variable containing
    # the boost that should be applied.
    #
    class BoostQuery < Connective::Conjunction
      def initialize(boost, setup)
        super(setup)
        @boost = boost
      end

      def to_boolean_phrase
        "#{super}^#{@boost}"
      end
    end
  end
end
