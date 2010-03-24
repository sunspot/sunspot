module Sunspot
  module Query
    class MoreLikeThisQuery < CommonQuery
      attr_accessor :scope, :more_like_this

      def initialize(document, types)
        super(types)
        @components << @more_like_this = MoreLikeThis.new(document)
      end
    end
  end
end
