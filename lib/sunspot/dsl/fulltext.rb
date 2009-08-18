module Sunspot
  module DSL
    class Fulltext
      def initialize(query)
        @query = query
      end

      def highlight(options = {})
        @query.set_highlight(options)
      end

      def phrase_fields(*fields)
        @query.set_phrase_fields(fields)
      end
    end
  end
end
