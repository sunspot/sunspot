module Sunspot
  module Query
    #
    # Representation of a GroupQuery, which allows the searcher to specify a
    # query to group matching documents. This is essentially a conjunction,
    # with an extra instance variable containing the label for the group.
    #
    class GroupQuery < Connective::Conjunction #:nodoc:
      attr_reader :label

      def initialize(label, negated = false)
        super(negated)
        @label = label
      end
    end
  end
end
