module Sunspot
  module Query
    class FulltextBaseQuery < BaseQuery
      def initialize(keywords, options, types, setup)
        super(types, setup)
        @keywords = keywords
        if highlight_options = options.delete(:highlight)
          if highlight_options == true
            set_highlight
          else
            set_highlight(highlight_options)
          end
        end
        if fulltext_fields = options.delete(:fields)
          Array(fulltext_fields).each do |field|
            add_fulltext_field(field)
          end
        end
      end

      def to_params
        params = { :q => @keywords }
        params[:fl] = '* score'
        params[:fq] = types_phrase
        params[:qf] = query_fields
        params[:defType] = 'dismax'
        if @phrase_fields
          params[:pf] = @phrase_fields.map { |field| field.to_boosted_field }.join(' ')
        end
        if @boost_query
          params[:bq] = @boost_query.to_boolean_phrase
        end
        if @highlight
          Sunspot::Util.deep_merge!(params, @highlight.to_params)
        end
        params
      end

      def add_fulltext_field(field_name, boost = nil)
        @fulltext_fields ||= []
        @fulltext_fields.concat(
          @setup.text_fields(field_name).map do |field|
            TextFieldBoost.new(field, boost)
          end
        )
      end

      def add_phrase_field(field_name, boost = nil)
        @phrase_fields ||= []
        @phrase_fields.concat(
          @setup.text_fields(field_name).map do |field|
            TextFieldBoost.new(field, boost)
          end
        )
      end

      def create_boost_query(factor)
        @boost_query ||= BoostQuery.new(factor, @setup)
      end

      def set_highlight(options = {})
        @highlight = Highlighting.new(options)
      end

      private

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
