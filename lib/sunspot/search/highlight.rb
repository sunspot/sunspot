module Sunspot
  class Search
    class Highlight
      #
      # The Regexp used to locate the highlighted words in a Highlight
      #
      HIGHLIGHT_MATCHER = /@@@hl@@@(.*)@@@endhl@@@/
      
      #
      # Highlighted keywords associated with this hit. Nil if this hit is not
      # from a keyword search.
      #
      attr_reader :highlight
      #
      # The name of the field in which the highlight appeared.
      #
      attr_reader :field_name
            
      #
      # Add a Highlight to the collection. The highlight is set to nil when Solr 
      # returns an empty highlight. This occurs on non-keyword searches.
      #
      def initialize(field_name, highlight)
        @field_name = field_name.to_sym
        @highlight = highlight.to_s.strip
      end
      
      #
      # Returns the highlighted text with formatting according to the template given in &block.
      # When no block is given, <em> and </em> are used to surround the highlight.
      #
      def format(&block)
        block ||= proc { |word| "<em>#{word}</em>" }
        highlight.gsub(HIGHLIGHT_MATCHER) do
          # I HATE having to use this magic global, but it seems like the only
          # way.
          block.call($1)
        end
      end
      alias_method :formatted, :format
      
    end
  end
end
