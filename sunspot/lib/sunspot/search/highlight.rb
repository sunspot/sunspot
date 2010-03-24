module Sunspot
  module Search
    # 
    # A Highlight represents a single highlighted fragment of text from a
    # document. Depending on the highlighting parameters used for search, there
    # may be more than one Highlight object for a given field in a given result.
    #
    class Highlight
      HIGHLIGHT_MATCHER = /@@@hl@@@(.*?)@@@endhl@@@/ #:nodoc:
      
      #
      # The name of the field in which the highlight appeared.
      #
      attr_reader :field_name
            
      def initialize(field_name, highlight) #:nodoc:
        @field_name = field_name.to_sym
        @highlight = highlight.to_s.strip
      end
      
      #
      # Returns the highlighted text with formatting according to the template given in &block.
      # When no block is given, &lt;em&gt; and &lt;/em&gt; are used to surround the highlight.
      #
      # ==== Example
      #
      #   search.highlights(:body).first.format { |word| "<strong>#{word}</strong>" }
      #
      def format(&block)
        block ||= proc { |word| "<em>#{word}</em>" }
        @highlight.gsub(HIGHLIGHT_MATCHER) do
          block.call(Regexp.last_match[1])
        end
      end
      alias_method :formatted, :format
    end
  end
end
