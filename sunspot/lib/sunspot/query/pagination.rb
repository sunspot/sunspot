module Sunspot
  module Query
    # 
    # A query component that holds information about pagination. Unlike other
    # query components, this one is mutable, because the query itself holds a
    # reference to it and updates it if pagination is changed.
    #
    class Pagination #:nodoc:
      attr_reader :page, :per_page, :offset

      def initialize(page = nil, per_page = nil, offset = nil)
        self.offset, self.page, self.per_page = offset, page, per_page
      end

      def to_params
        { :start => start, :rows => rows }
      end

      def page=(page)
        @page = page.to_i if page
      end

      def per_page=(per_page)
        @per_page = per_page.to_i if per_page
      end

      def offset=(offset)
        @offset = offset.to_i
      end

      private

      def start
        (@page - 1) * @per_page + @offset
      end

      def rows
        @per_page
      end
    end
  end
end
