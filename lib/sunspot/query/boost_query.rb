module Sunspot
  module Query
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
