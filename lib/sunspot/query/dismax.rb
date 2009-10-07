module Sunspot
  module Query
    class Dismax
      def initialize(keywords)
        @keywords = keywords
        @fulltext_fields = {}
      end

      # 
      # The query as Solr parameters
      #
      def to_params
        params = { :q => @keywords }
        params[:fl] = '* score'
        params[:qf] = @fulltext_fields.values.map { |field| field.to_boosted_field }.join(' ')
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

      # 
      # Assign a new boost query and return it.
      #
      def create_boost_query(factor)
        @boost_query = BoostQuery.new(factor)
      end

      # 
      # Add a fulltext field to be searched, with optional boost
      #
      def add_fulltext_field(field, boost = nil)
        @fulltext_fields[field.indexed_name] = TextFieldBoost.new(field, boost)
      end

      #
      # Add a phrase field for extra boost
      #
      def add_phrase_field(field, boost = nil)
        @phrase_fields ||= []
        @phrase_fields << TextFieldBoost.new(field, boost)
      end

      # 
      # Set highlighting options for the query. If fields is empty, the
      # Highlighting object won't pass field names at all, which means
      # the dismax's :qf parameter will be used by Solr.
      #
      def set_highlight(fields=[], options={})
        @highlight = Highlighting.new(fields, options)
      end

      # 
      # Determine if a given field is being searched. Used by DSL to avoid
      # overwriting boost parameters when injecting defaults.
      #
      def has_fulltext_field?(field)
        @fulltext_fields.has_key?(field.indexed_name)
      end
    end
  end
end
