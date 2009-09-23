module Sunspot
  module Query
    class Dismax
      attr_reader :fulltext_fields

      def initialize(keywords)
        @keywords = keywords
        @fulltext_fields = []
      end

      def to_params
        params = { :q => @keywords }
        params[:fl] = '* score'
        params[:qf] = @fulltext_fields.map { |field| field.to_boosted_field }.join(' ')
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

      def create_boost_query(factor)
        @boost_query = BoostQuery.new(factor)
      end

      def add_fulltext_fields(fields, boost = nil)
        @fulltext_fields ||= []
        @fulltext_fields.concat(
          fields.map do |field|
            TextFieldBoost.new(field, boost)
          end
        )
      end

      def add_phrase_fields(fields, boost = nil)
        @phrase_fields ||= []
        @phrase_fields.concat(
          fields.map do |field|
            TextFieldBoost.new(field, boost)
          end
        )
      end

      def set_highlight(fields=[], options={})
        if fields.empty?
          fields = @fulltext_fields.map do |fulltext_field|
            fulltext_field.field
          end
        end
        @highlight = Highlighting.new(fields, options)
      end
    end
  end
end
