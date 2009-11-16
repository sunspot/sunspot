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
    class Query < FieldQuery
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
        if keywords && !(keywords.to_s =~ /^\s*$/)
          fulltext_query = @query.set_fulltext(keywords)
          if field_names = options.delete(:fields)
            Util.Array(field_names).each do |field_name|
              @setup.text_fields(field_name).each do |field|
                fulltext_query.add_fulltext_field(field, field.default_boost)
              end
            end
          end
          if minimum_match = options.delete(:minimum_match)
            fulltext_query.minimum_match = minimum_match.to_i
          end
          if tie = options.delete(:tie)
            fulltext_query.tie = tie.to_f
          end
          if query_phrase_slop = options.delete(:query_phrase_slop)
            fulltext_query.query_phrase_slop = query_phrase_slop.to_i
          end
          if highlight_field_names = options.delete(:highlight)
            if highlight_field_names == true
              fulltext_query.add_highlight
            else
              highlight_fields = []
              Util.Array(highlight_field_names).each do |field_name|
                highlight_fields.concat(@setup.text_fields(field_name))
              end
              fulltext_query.add_highlight(highlight_fields)
            end
          end
          if block && fulltext_query
            fulltext_dsl = Fulltext.new(fulltext_query, @setup)
            Util.instance_eval_or_call(
              fulltext_dsl,
              &block
            )
          end
          if !field_names && (!fulltext_dsl || !fulltext_dsl.fields_added?)
            @setup.all_text_fields.each do |field|
              unless fulltext_query.has_fulltext_field?(field)
                unless fulltext_dsl && fulltext_dsl.exclude_fields.include?(field.name)
                  fulltext_query.add_fulltext_field(field, field.default_boost)
                end
              end
            end
          end
        end
      end
      alias_method :keywords, :fulltext

      # Paginate your search. This works the same way as WillPaginate's
      # paginate().
      #
      # Note that Solr searches are _always_ paginated. Not calling #paginate is
      # the equivalent of calling:
      #
      #   paginate(:page => 1, :per_page => Sunspot.config.pagination.default_per_page)
      #
      # ==== Options (options)
      #
      # :page<Integer,String>:: The requested page. The default is 1.
      #
      # :per_page<Integer,String>::
      #   How many results to return per page. The default is the value in
      #   +Sunspot.config.pagination.default_per_page+
      #
      def paginate(options = {})
        page = options.delete(:page)
        per_page = options.delete(:per_page)
        raise ArgumentError, "unknown argument #{options.keys.first.inspect} passed to paginate" unless options.empty?
        @query.paginate(page, per_page)
      end

      # <strong>Expert:</strong> Adjust or reset the parameters passed to Solr.
      # The adjustment will take place just before sending the params to solr,
      # after Sunspot builds the Solr params based on the methods called in the
      # DSL.
      #
      # Under normal circumstances, using this method should not be necessary;
      # if you find that it is, please consider submitting a feature request.
      # Using this method requires knowledge of Sunspot's internal Solr schema
      # and Solr query representations, which are not part of Sunspot's public
      # API; they could change at any time. <strong>This method is unsupported
      # and your mileage may vary.</strong>
      #
      # ==== Example
      #
      #   Sunspot.search(Post) do
      #     adjust_solr_params do |params|
      #       params[:q] += ' AND something_s:more'
      #     end
      #   end
      # 
      def adjust_solr_params( &block )
        @query.set_solr_parameter_adjustment( block )
      end

      # 
      # Scope the search by geographical distance from a given point.
      # +coordinates+ should either respond to #first and #last (e.g. a
      # two-element array), or to #lat and one of #lng, #lon, or #long.
      # +miles+ is the radius around the point for which to return documents.
      #
      def near(coordinates, miles)
        @query.add_location_restriction(coordinates, miles)
      end
    end
  end
end
