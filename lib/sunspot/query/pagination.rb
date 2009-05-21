module Sunspot
  class Query
    class Pagination
      attr_reader :page, :per_page

      def initialize(configuration, page = nil, per_page = nil)
        @page, @per_page = page || 1, per_page || configuration.pagination.default_per_page
      end

      def to_params
        { :start => start, :rows => rows }
      end

      private

      def start
        (@page - 1) * @per_page
      end

      def rows
        @per_page
      end
    end
  end
end
