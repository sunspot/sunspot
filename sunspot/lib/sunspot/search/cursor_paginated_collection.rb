module Sunspot
  module Search
    class CursorPaginatedCollection < Array
      attr_reader :per_page, :total_count, :current_cursor, :next_page_cursor
      alias :total_entries :total_count
      alias :limit_value :per_page

      def initialize(collection, per_page, total, current_cursor, next_page_cursor)
        @per_page         = per_page
        @total_count      = total
        @current_cursor   = current_cursor
        @next_page_cursor = next_page_cursor

        replace collection
      end

      def total_pages
        (total_count.to_f / per_page).ceil
      end
      alias :num_pages :total_pages

      def first_page?
        current_cursor == '*'
      end

      def last_page?
        count < per_page
      end
    end
  end
end
