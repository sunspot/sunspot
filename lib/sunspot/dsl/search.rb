module Sunspot
  module DSL
    class Search < Query
      def initialize(search)
        @search = search
        @query = search.query
      end

      def data_accessor_for(clazz)
        @search.data_accessor_for(clazz)
      end
    end
  end
end
