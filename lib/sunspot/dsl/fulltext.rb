module Sunspot
  module DSL
    class Fulltext
      def initialize(query)
        @query = query
      end

      def highlight(options = {})
        @query.set_highlight(options)
      end
    end
  end
end
