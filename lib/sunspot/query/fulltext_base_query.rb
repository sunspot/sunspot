module Sunspot
  module Query
    class FulltextBaseQuery < BaseQuery #:nodoc:
      def initialize(keywords, options, types, setup)
        super(types, setup)
        @keywords = keywords

        if highlight_options = options.delete(:highlight)
          set_highlight(highlight_options == true ? [] : highlight_options)
        end

        if fulltext_fields = options.delete(:fields)
          Array(fulltext_fields).each do |field|
            add_fulltext_field(field)
          end
        end
      end


      private

      def text_fields(field_names)
        field_names.inject([]) do |fields, name|
          fields.concat(@setup.text_fields(name))
        end
      end

      # 
      # Returns the names of text fields that should be queried in a keyword
      # search. If specific fields are requested, use those; otherwise use the
      # union of all fields configured for the types under search.
      #
      def query_fields
        @query_fields ||=
          begin
            fulltext_fields =
              @fulltext_fields || @setup.all_text_fields.map do |field|
                TextFieldBoost.new(field)
              end
            fulltext_fields.map do |fulltext_field|
              fulltext_field.to_boosted_field
            end.join(' ')
          end
      end
    end
  end
end
