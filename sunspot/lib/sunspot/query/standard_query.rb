module Sunspot
  module Query
    class StandardQuery < CommonQuery
      attr_accessor :scope, :fulltext

      def initialize(types)
        super
        @components << @fulltext = CompositeFulltext.new
      end

      def add_fulltext(keywords,parser=nil)
        @fulltext.add(keywords,parser)
      end
    end
  end
end
