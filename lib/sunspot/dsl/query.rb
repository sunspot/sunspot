module Sunspot
  module DSL #:nodoc:
    #
    # This class presents a DSL for constructing queries using the
    # Sunspot.search method. Methods of this class are available inside the
    # search block. Methods that take field names as arguments are implemented
    # in the superclass Sunspot::DSL::Scope, as that DSL is also available in
    # the #dynamic() block.
    #
    # See Sunspot.search for usage examples
    #
    class Query < FieldQuery
      # Specify a phrase that should be searched as fulltext. Only +text+
      # fields are searched - see DSL::Fields.text
      #
      # Note that the keywords are passed directly to Solr unadulterated. The
      # advantage of this is that users can potentially use boolean logic to
      # make advanced searches. The disadvantage is that syntax errors are
      # possible. This may get better in a future version; suggestions are
      # welcome.
      #
      # ==== Parameters
      #
      # keywords<String>:: phrase to perform fulltext search on
      #
      def keywords(keywords, options = {})
        @query.set_keywords(keywords, options)
      end

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
      # :page<Integer>:: The requested page (required)
      #
      # :per_page<Integer>::
      #   How many results to return per page. The default is the value in
      #   +Sunspot.config.pagination.default_per_page+
      #
      def paginate(options = {})
        page = options.delete(:page) || raise(ArgumentError, "paginate requires a :page argument")
        per_page = options.delete(:per_page)
        raise ArgumentError, "unknown argument #{options.keys.first.inspect} passed to paginate" unless options.empty?
        @query.paginate(page, per_page)
      end
    end
  end
end
