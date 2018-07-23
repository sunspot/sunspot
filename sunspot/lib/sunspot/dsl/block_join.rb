module Sunspot
  module DSL
    # TODO(ar3s3ru): document this!
    module BlockJoin
      def child_of(parent_type, &block)
        @query.add_function(
          block_join_query(parent_type, Query::BlockJoin::ChildOf, &block)
        )
      end

      def parent_which(children_type, &block)
        @query.add_function(
          block_join_query(children_type, Query::BlockJoin::ParentWhich, &block)
        )
      end

      private

      def block_join_query(inner_type, block_join_clazz, &block)
        # Use a cloned search with parent type setup to keep using the DSL
        new_search = @search.clone(
          Query::StandardQuery.new([inner_type]),
          Sunspot::Setup.for(inner_type),
          Configuration.build
        )
        new_search.build(&block) if block
        block_join_clazz.new(@scope, new_search.query)
      end
    end
  end
end
