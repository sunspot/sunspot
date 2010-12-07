module Sunspot
  module Query
    # 
    # A query component that holds information about pagination. Unlike other
    # query components, this one is mutable, because the query itself holds a
    # reference to it and updates it if pagination is changed.
    #
    class Pagination #:nodoc:
      attr_reader :page, :per_page, :start_offset

      # the Solr start parameter can be offset by setting start_offset
      # By default, the start_offset is 0
      def initialize(page = nil, per_page = nil, start_offset = 0)
        self.page, self.per_page, self.start_offset = page, per_page, start_offset
      end

      def to_params
        { :start => start, :rows => rows }
      end

      def page=(page)
        @page = page.to_i if page
      end

      # if a start_offset is set, pagination will be offset so as not to include duplicates in subsequent pagination
      def per_page=(per_page)
        @per_page = per_page.to_i + @start_offset if per_page
      end

      def start_offset
        @start_offset.to_i
      end


      private

      def start
        (@page - 1) * @per_page + @start_offset
      end

      def rows
        @per_page
      end

    end
  end
end