module Sunspot
  class Search
    class Highlight
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
    end
  end
end