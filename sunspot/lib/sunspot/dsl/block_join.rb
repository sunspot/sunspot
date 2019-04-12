module Sunspot
  module DSL
    #
    # Module BlockJoin implements DSL functions to enable BlockJoin queries
    # and BlockJoin Faceting through JSON API.
    #
    # ==== ChildOf vs. ParentWhich
    #
    # To make a BlockJoin query to retrieve parent documents using a filter
    # on children, use +parent_which+ method.
    #
    # To make a BlockJoin query to retrieve child documents using a filter
    # on parents, use +child_of+ method.
    #
    # In both cases, you can pass a block to the method chosen to perform
    # additional filtering on targeted documents.
    #
    module BlockJoin
      #
      # Declares a BlockJoin query to be executed on all parent documents
      # of the provided class.
      #
      # ==== Examples
      #
      #   # A BlockJoin query that returns all children documents
      #   # that have at least a parent that speaks english
      #   Sunspot.search(Child) do
      #     child_of(Parent) do
      #       with :speak, 'english'
      #     end
      #   end
      #
      def child_of(parent_type, &block)
        Sunspot::Util.ensure_child_documents_support
        @query.add_function(
          block_join_query(parent_type, Query::BlockJoin::ChildOf, &block)
        )
      end

      #
      # Declares a BlockJoin query to be executed on all child documents
      # of the provided class.
      #
      # ==== Example
      #
      #   # A BlockJoin query that returns all Parent documents
      #   # that have at least a 18 years old child
      #   Sunspot.search(Parent) do
      #     parent_which(Child) do
      #       with(:age).greater_than(17)
      #     end
      #   end
      #
      def parent_which(children_type, &block)
        Sunspot::Util.ensure_child_documents_support
        @query.add_function(
          block_join_query(children_type, Query::BlockJoin::ParentWhich, &block)
        )
      end

      private

      #
      # Returns the +Sunspot::Query::BlockJoin+ class that can be used both
      # in BlockJoin queries or faceting, cloning the existing search to make
      # a nested search (for generating additional filtering using the same DSL).
      #
      # ==== Returns
      #
      # Sunspot::Query::BlockJoin::
      #   Block Join query object, with filtering already executed and
      #   query parameters ready to be included into the general search.
      #
      def block_join_query(inner_type, block_join_clazz, &block)
        # Use a cloned search with parent type setup to keep using the DSL
        new_search = Sunspot::Search::StandardSearch.new(nil,
                                                         Sunspot::Setup.for(inner_type),
                                                         Query::StandardQuery.new([inner_type]),
                                                         Configuration.build)
        new_search.build(&block) if block
        block_join_clazz.new(@scope, new_search.query)
      end
    end
  end
end
