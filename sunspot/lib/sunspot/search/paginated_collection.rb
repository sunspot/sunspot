module Sunspot
  module Search

    class PaginatedCollection < Array

      attr_reader :current_page, :per_page
      attr_accessor :total_count
      alias :total_entries :total_count
      alias :total_entries= :total_count=
      alias :limit_value :per_page

      def initialize(collection, page, per_page, total)
        @current_page = page
        @per_page     = per_page
        @total_count  = total
        replace collection
      end

      def total_pages
        (total_count.to_f / per_page).ceil
      end
      alias :num_pages :total_pages

      def first_page?
        current_page == 1
      end

      def last_page?
        current_page >= total_pages
      end

      def previous_page
        current_page > 1 ? (current_page - 1) : nil
      end

      def next_page
        current_page < total_pages ? (current_page + 1) : nil
      end

      def out_of_bounds?
        current_page > total_pages
      end

      def offset
        (current_page - 1) * per_page
      end
      alias :offset_value :offset

    end
  end
end
