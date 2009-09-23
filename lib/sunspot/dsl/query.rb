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
      #
      def fulltext(keywords, options = {}, &block)
        if keywords && !(keywords.to_s =~ /^\s*$/)
          fulltext_query = @query.set_fulltext(keywords)
          if field_names = options.delete(:fields)
            Array(field_names).each do |field_name|
              fulltext_query.add_fulltext_fields(@setup.text_fields(field_name))
            end
          end
          if highlight_field_names = options.delete(:highlight)
            if highlight_field_names == true
              fulltext_query.set_highlight
            else
              highlight_fields = []
              Array(highlight_field_names).each do |field_name|
                highlight_fields.concat(@setup.text_fields(field_name))
              end
              fulltext_query.set_highlight(highlight_fields)
            end
          end
          if block && fulltext_query
            Util.instance_eval_or_call(
              Fulltext.new(fulltext_query, @setup),
              &block
            )
          end
          if fulltext_query.fulltext_fields.empty?
            fulltext_query.add_fulltext_fields(@setup.all_text_fields)
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

      # 
      # Scope the search by geographical distance from a given point.
      # +coordinates+ should either respond to #first and #last (e.g. a
      # two-element array), or to #lat and one of #lng, #lon, or #long.
      # +miles+ is the radius around the point for which to return documents.
      #
      def near(coordinates, miles)
        @query.add_location_restriction(coordinates, miles)
      end

      # 
      # Apply scope-type restrictions on fulltext fields. In certain situations,
      # it may be desirable to place logical restrictions on text fields.
      # Remember that text fields are tokenized; your mileage may very.
      #
      # The block works exactly like a normal scope, except that the field names
      # refer to text fields instead of attribute fields.
      # 
      # === Example
      #
      #   Sunspot.search(Post) do
      #     text_fields do
      #       with :body, nil
      #     end
      #   end
      #
      # This will return all documents that do not have a body.
      #
      def text_fields(&block)
        Sunspot::Util.instance_eval_or_call(
          Scope.new(@scope, TextFieldSetup.new(@setup)),
          &block
        )
      end
    end
  end
end
