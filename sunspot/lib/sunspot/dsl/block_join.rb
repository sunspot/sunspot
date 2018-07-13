module Sunspot
  module DSL
    class BlockJoin < Scope
      def child_of(parents_filter, &block)
        puts parents_filter
      end

      def parent_which(parents_filter, &block)
        puts parents_filter
      end
    end
  end
end