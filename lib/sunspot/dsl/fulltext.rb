module Sunspot
  module DSL
    class Fulltext
      def initialize(query)
        @query = query
      end

      def fields(*fields)
        boosted_fields = fields.pop if fields.last.is_a?(Hash)
        fields.each do |field_name|
          @query.add_fulltext_field(field_name)
        end
        boosted_fields.each_pair do |field_name, boost|
          @query.add_fulltext_field(field_name, boost)
        end
      end

      def highlight(options = {})
        @query.set_highlight(options)
      end

      def phrase_fields(*fields)
        boosted_fields = fields.pop if fields.last.is_a?(Hash)
        fields.each do |field_name|
          @query.add_phrase_field(field_name)
        end
        if boosted_fields
          boosted_fields.each_pair do |field_name, boost|
            @query.add_phrase_field(field_name, boost)
          end
        end
      end
    end
  end
end
