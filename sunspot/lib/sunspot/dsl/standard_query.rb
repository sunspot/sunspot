module Sunspot
  module DSL #:nodoc:
    #
    # This class presents a DSL for constructing queries using the
    # Sunspot.search method. Methods of this class are available inside the
    # search block. Much of the DSL's functionality is implemented by this
    # class's superclasses, Sunspot::DSL::FieldQuery and Sunspot::DSL::Scope
    #
    # See Sunspot.search for usage examples
    #
    class StandardQuery < FieldQuery
      include Paginatable, Adjustable, Spellcheckable

      # Specify a phrase that should be searched as fulltext. Only +text+
      # fields are searched - see DSL::Fields.text
      #
      # Keyword search is executed using Solr's dismax handler, which strikes
      # a good balance between powerful and foolproof. In particular,
      # well-matched quotation marks can be used to group phrases, and the
      # + and - modifiers work as expected. All other special Solr boolean
      # syntax is escaped, and mismatched quotes are ignored entirely.
      #
      # This method can optionally take a block, which is evaluated by the
      # Fulltext DSL class, and exposes several powerful dismax features.
      #
      # ==== Parameters
      #
      # keywords<String>:: phrase to perform fulltext search on
      #
      # ==== Options
      #
      # :fields<Array>::
      #   List of fields that should be searched for keywords. Defaults to all
      #   fields configured for the types under search.
      # :highlight<Boolean,Array>::
      #   If true, perform keyword highlighting on all searched fields. If an
      #   array of field names, perform highlighting on the specified fields.
      #   Note that for highlighting to work, the desired fields have to be set
      #   up with :stored => true.
      #   This can also be called from within the fulltext block.
      # :minimum_match<Integer>::
      #   The minimum number of search terms that a result must match. By
      #   default, all search terms must match; if the number of search terms
      #   is less than this number, the default behavior applies.
      # :tie<Float>::
      #   A tiebreaker coefficient for scores derived from subqueries that are
      #   lower-scoring than the maximum score subquery. Typically a near-zero
      #   value is useful. See
      #   http://wiki.apache.org/solr/DisMaxRequestHandler#tie_.28Tie_breaker.29
      #   for more information.
      # :query_phrase_slop<Integer>::
      #   The number of words that can appear between the words in a
      #   user-entered phrase (i.e., keywords in quotes) and still match. For
      #   instance, in a search for "\"great pizza\"" with a phrase slop of 1,
      #   "great pizza" and "great big pizza" will match, but "great monster of
      #   a pizza" will not. Default behavior is a query phrase slop of zero.
      #
      def fulltext(keywords, options = {}, &block)
        return if not keywords or keywords.to_s =~ /^\s*$/

        field_names = Util.Array(options.delete(:fields)).compact

        add_fulltext(keywords, field_names) do |query, fields|
          query.minimum_match = options.delete(:minimum_match).to_i if options.key?(:minimum_match)
          query.tie = options.delete(:tie).to_f if options.key?(:tie)
          query.query_phrase_slop = options.delete(:query_phrase_slop).to_i if options.key?(:query_phrase_slop)

          if highlight_field_names = options.delete(:highlight)
            if highlight_field_names == true
              query.add_highlight
            else
              highlight_fields = []
              Util.Array(highlight_field_names).each do |field_name|
                highlight_fields.concat(@setup.text_fields(field_name))
              end
              query.add_highlight(highlight_fields)
            end
          end

          if block && query
            fulltext_dsl = Fulltext.new(query, @setup)
            Util.instance_eval_or_call(fulltext_dsl, &block)
          else
            fulltext_dsl = nil
          end

          if fields.empty? && (!fulltext_dsl || !fulltext_dsl.fields_added?)
            @setup.all_text_fields.each do |field|
              unless query.has_fulltext_field?(field)
                unless fulltext_dsl && fulltext_dsl.exclude_fields.include?(field.name)
                  query.add_fulltext_field(field, field.default_boost)
                end
              end
            end
          end
        end
      end

      alias_method :keywords, :fulltext

      def with(*args)
        case args.first
          when String, Symbol
            if args.length == 1 # NONE
              field = @setup.field(args[0].to_sym)
              return DSL::RestrictionWithNear.new(field, @scope, @query, false)
            end
        end

        # else
        super
      end

      def any(&block)
        @query.disjunction do
          Util.instance_eval_or_call(self, &block)
        end
      end

      def all(&block)
        @query.conjunction do
          Util.instance_eval_or_call(self, &block)
        end
      end

      private

      def add_fulltext(keywords, field_names)
        return yield(@query.add_fulltext(keywords), []) unless field_names.any?

        all_fields = field_names.map { |name| @setup.text_fields(name) }.flatten
        all_fields -= join_fields = all_fields.find_all(&:joined?)

        if all_fields.any?
          fulltext_query = @query.add_fulltext(keywords)
          all_fields.each { |field| fulltext_query.add_fulltext_field(field, field.default_boost) }
          yield(fulltext_query, all_fields)
        end

        if join_fields.any?
          join_fields.group_by { |field| [field.target, field.from, field.to] }.each_pair do |(target, from, to), fields|
            join_query = @query.add_join(keywords, target, from, to)
            fields.each { |field| join_query.add_fulltext_field(field, field.default_boost) }
            yield(join_query, fields)
          end
        end
      end
    end
  end
end
