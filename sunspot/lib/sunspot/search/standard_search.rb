module Sunspot
  module Search
    # 
    # This class encapsulates the results of a Solr search. It provides access
    # to search results, total result count, facets, and pagination information.
    # Instances of Search are returned by the Sunspot.search and
    # Sunspot.new_search methods.
    #
    class StandardSearch < AbstractSearch
      def request_handler
        super || :select
      end
  
      private
  
      def dsl
        DSL::Search.new(self, @setup)
      end
    end
  end
end
