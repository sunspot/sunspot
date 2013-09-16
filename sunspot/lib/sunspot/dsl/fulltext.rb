module Sunspot
  module DSL
    # 
    # This DSL exposes the functionality provided by Solr's fulltext Dismax
    # handler.
    #
    class Fulltext
      # accept function in boost
      include Functional

      def initialize(query, setup) #:nodoc:
        @query, @setup = query, setup
        @fields_added = false
        @exclude_fields = []
      end

      # 
      # Specify which fields to search. Field names specified as arguments are
      # given default boost; field boosts can be specified by passing a hash of
      # field names keyed to boost values as the last argument.
      #
      # If you wish to boost certain fields without restricting which fields are
      # searched, use #boost_fields
      #
      # === Example
      #
      #   Sunspot.search(Post) do
      #     keywords 'search is cool' do
      #       fields(:body, :title => 2.0)
      #     end
      #   end
      #
      # This would search the :body field with default boost (1.0), and the :title
      # field with a boost of 2.0
      #
      def fields(*field_names)
        @fields_added = true
        boosted_fields = field_names.pop if field_names.last.is_a?(Hash)
        field_names.each do |field_name|
          @setup.text_fields(field_name).each do |field|
            @query.add_fulltext_field(field, field.default_boost)
          end
        end
        if boosted_fields
          boosted_fields.each_pair do |field_name, boost|
            @setup.text_fields(field_name).each do |field|
              @query.add_fulltext_field(field, boost)
            end
          end
        end
      end

      # 
      # Exclude the given fields from the search. All fields that are configured
      # for the types under search and not listed here will be searched.
      #
      def exclude_fields(*field_names)
        @exclude_fields.concat(field_names)
      end

      # 
      # Enable keyword highlighting for this search. By default, the fields 
      # under search will be highlighted; you may also may pass one or more
      # symbol arguments indicating fields to be highlighted (they don't even
      # have to be the same fields you're searching).
      #
      # === Example
      #
      #   Sunspot.search(Post) do
      #     keywords 'show me the highlighting' do
      #       highlight :title, :body
      #     end
      #   end
      #
      # You may also pass a hash of options as the last argument. Options are
      # the following:
      #
      # Full disclosure: I barely understand what these options actually do;
      # this documentation is pretty much just copied from the
      # (http://wiki.apache.org/solr/HighlightingParameters#head-23ecd5061bc2c86a561f85dc1303979fe614b956)[Solr Wiki]
      # 
      # :max_snippets::
      #   The maximum number of highlighted snippets to generate per field
      # :fragment_size::
      #   The number of characters to consider for a highlighted fragment
      # :merge_continuous_fragments::
      #   Collapse continuous fragments into a single fragment
      # :phrase_highlighter::
      #   Highlight phrase terms only when they appear within the query phrase
      #   in the document
      # :require_field_match::
      #   If true, a field will only be highlighted if the query matched in
      #   this particular field (only has an effect if :phrase_highlighter is
      #   true as well)
      #
      def highlight(*args)
        options = args.last.kind_of?(Hash) ? args.pop : {}
        fields = []
        args.each { |field_name| fields.concat(@setup.text_fields(field_name)) }

        @query.add_highlight(fields, options)
      end

      # 
      # Phrase fields are an awesome dismax feature that adds extra boost to
      # documents for which all the fulltext keywords appear in close proximity
      # in one of the given fields. Excellent for titles, headlines, etc.
      #
      # Boosted fields are specified in a hash of field names to a boost, as
      # with the #fields and #boost_fields methods.
      #
      # === Example
      #
      #   Sunspot.search(Post) do
      #     keywords 'nothing reveals like relevance' do
      #       phrase_fields :title => 2.0
      #     end
      #   end
      #
      def phrase_fields(boosted_fields)
        if boosted_fields
          boosted_fields.each_pair do |field_name, boost|
            @setup.text_fields(field_name).each do |field|
              @query.add_phrase_field(field, boost)
            end
          end
        end
      end

      # 
      # The maximum number of words that can appear between search terms for a
      # field to qualify for phrase field boost. See #query_phrase_slop for
      # examples. Phrase slop is only meaningful if phrase fields are specified
      # (see #phrase_fields), and it does not have an effect on which results
      # are returned; only on what their respective boosts are.
      #
      def phrase_slop(slop)
        @query.phrase_slop = slop
      end

      # 
      # Boost queries allow specification of an arbitrary scope for which
      # matching documents should receive an extra boost. You can either specify 
      # a boost factor and a block, or a boost function. The block is evaluated
      # in the usual scope DSL, and field names are attribute fields, not text
      # fields, as in other scope.
      #
      # The boost function can be a constant (numeric or string literal), 
      # a field name or another function. You can build arbitrarily complex 
      # functions, which are passed transparently to solr.
      #
      # This method can be called more than once for different boost queries
      # with different boosts.
      #
      # === Example
      #
      #   Sunspot.search(Post) do
      #     keywords 'super fan' do
      #       boost(2.0) do
      #         with(:featured, true)
      #       end
      #
      #       boost(function { sum(:average_rating, product(:popularity, 10)) })
      #     end
      #   end
      #
      # In the above search, featured posts will receive a boost of 2.0 and all posts 
      # will be boosted by (average_rating + popularity * 10).
      #
      def boost(factor_or_function, &block)
        if factor_or_function.is_a?(Sunspot::Query::FunctionQuery)
          @query.add_boost_function(factor_or_function)
        else
          Sunspot::Util.instance_eval_or_call(
            Scope.new(@query.create_boost_query(factor_or_function), @setup),
            &block
          )
        end
      end

      #
      # Add boost to certain fields, without restricting which fields are
      # searched.
      #
      # === Example
      #
      #   Sunspot.search(Post) do
      #     keywords('pork sandwich') do
      #       boost_fields :title => 1.5
      #     end
      #   end
      #
      def boost_fields(boosts)
        boosts.each_pair do |field_name, boost|
          begin
            @setup.text_fields(field_name).each do |field|
              @query.add_fulltext_field(field, boost)
            end
          rescue Sunspot::UnrecognizedFieldError
            # We'll let this one slide.
          end
        end
      end
      
      #
      # The minimum number of search terms that a result must match. By
      # default, all search terms must match; if the number of search terms
      # is less than this number, the default behavior applies.
      #
      def minimum_match(minimum_match)
        @query.minimum_match = minimum_match
      end

      #
      # The number of words that can appear between the words in a
      # user-entered phrase (i.e., keywords in quotes) and still match. For
      # instance, in a search for "\"great pizza\"" with a query phrase slop of
      # 1, "great pizza" and "great big pizza" will match, but "great monster of
      # a pizza" will not. Default behavior is a query phrase slop of zero.
      #
      def query_phrase_slop(slop)
        @query.query_phrase_slop = slop
      end

      #
      # A tiebreaker coefficient for scores derived from subqueries that are
      # lower-scoring than the maximum score subquery. Typically a near-zero
      # value is useful. See
      # http://wiki.apache.org/solr/DisMaxRequestHandler#tie_.28Tie_breaker.29
      # for more information.
      #
      def tie(tie)
        @query.tie = tie
      end

      def fields_added? #:nodoc:
        @fields_added
      end
    end
  end
end
