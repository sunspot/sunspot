module Sunspot
  class Search
    class Highlight
      # 
      # Primary key of object associated with this highlight, as string.
      #
      attr_reader :primary_key
      # 
      # Class name of object associated with this highlight, as string.
      #
      attr_reader :class_name
      #
      # Highlighted keywords associated with this hit. Nil if this hit is not
      # from a keyword search.
      #
      attr_reader :highlight
      
      #
      # Add a Highlight to the collection. The highlight is set to nil when Solr 
      # returns an empty highlight. This occurs on non-keyword searches.
      # 
      # The highlight-attribute looks like this: [ "Post 23", { 'field_text' => [ 'The <em>highlighted</em> text' ] } ]
      #
      def initialize(highlight)
        @class_name, @primary_key = highlight.first.match(/([^ ]+) (.+)/)[1..2]
        @highlight = highlight.last.values.to_s.empty? ? nil : highlight.last.values.to_s
      end
    end
  end
end