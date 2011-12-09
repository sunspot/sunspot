module Sunspot
  module DSL #:nodoc
    module Paginatable
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
      # :offset<Integer,String>::
      #   Applies a shift to paginated records. The default is 0.
      #
      def paginate(options = {})
        page = options.delete(:page)
        per_page = options.delete(:per_page)
        offset = options.delete(:offset)
        raise ArgumentError, "unknown argument #{options.keys.first.inspect} passed to paginate" unless options.empty?
        @query.paginate(page, per_page, offset)
      end
    end
  end
end
