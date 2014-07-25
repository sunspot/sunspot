module Sunspot
  module Query

    #
    # Solr full-text queries use Solr's JoinRequestHandler.
    #
    class Join < AbstractFulltext
      attr_writer :minimum_match, :phrase_slop, :query_phrase_slop, :tie

      def initialize(keywords, target, from, to)
        @keywords = keywords
        @target = target
        @from = from
        @to = to

        @fulltext_fields = {}

        @minimum_match = nil
      end

      #
      # The query as Solr parameters
      #
      def to_params
        params = { :q => @keywords }
        params[:fl] = '* score'
        params[:qf] = @fulltext_fields.values.map { |field| field.to_boosted_field }.join(' ')
        params[:defType] = 'join'
        params[:mm] = @minimum_match if @minimum_match

        params
      end

      #
      # Serialize the query as a Solr nested subquery.
      #
      def to_subquery
        params = self.to_params
        params.delete :defType
        params.delete :fl

        keywords = escape_quotes(params.delete(:q))
        options = params.map { |key, value| escape_param(key, value) }.join(' ')
        q_name = "q#{@target.name}#{self.object_id}"
        fq_name = "f#{q_name}"

        {
          :q => "_query_:\"{!join from=#{@from} to=#{@to} v=$#{q_name} fq=$#{fq_name}}\"",
          q_name => "_query_:\"{!edismax #{options}}#{keywords}\"",
          fq_name => "type:#{@target.name}"
        }
      end

      #
      # Assign a new boost query and return it.
      #
      def create_boost_query(factor)
      end

      #
      # Add a boost function
      #
      def add_boost_function(function_query)
      end

      #
      # Add a fulltext field to be searched, with optional boost.
      #
      def add_fulltext_field(field, boost = nil)
        @fulltext_fields[field.indexed_name] = TextFieldBoost.new(field, boost)
      end

      #
      # Add a phrase field for extra boost.
      #
      def add_phrase_field(field, boost = nil)
      end

      #
      # Set highlighting options for the query. If fields is empty, the
      # Highlighting object won't pass field names at all, which means
      # the dismax's :qf parameter will be used by Solr.
      #
      def add_highlight(fields=[], options={})
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
