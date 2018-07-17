module Sunspot
  module Search
    #
    # Module Cloneable adds a clone functionality for Search
    # using the mixin capability.
    #
    module Cloneable
      #
      # Clones the original search using the provided arguments for a new one,
      # but still using the original connection.
      #
      def clone(query, setup, config)
        StandardSearch.new(@connection, setup, query, config)
      end
    end
  end
end