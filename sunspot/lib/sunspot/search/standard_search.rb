module Sunspot
  module Search
    # 
    # This class encapsulates the results of a Solr search. It provides access
    # to search results, total result count, facets, and pagination information.
    # Instances of Search are returned by the Sunspot.search and
    # Sunspot.new_search methods.
    #
    class StandardSearch < AbstractSearch
  
      private
  
      def dsl
        DSL::Search.new(self, @setup)
      end
  
      def execute_request(params)
        @connection.select(params)
      end
    end
  end
end
