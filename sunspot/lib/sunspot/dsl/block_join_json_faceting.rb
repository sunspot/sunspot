module Sunspot
  module DSL
    module BlockJoin
      # TODO(ar3s3ru): add documentation
      module JsonFaceting
        def on_child(type, &block)
          {
            op: Sunspot::Query::BlockJoin::JsonFacet::ON_CHILDREN_OP,
            type: type,
            query: block_join_query(type, Sunspot::Query::BlockJoin::ParentWhich, &block)
          }
        end

        def on_parent(type, &block)
          {
            op: Sunspot::Query::BlockJoin::JsonFacet::ON_PARENTS_OP,
            type: type,
            query: block_join_query(type, Sunspot::Query::BlockJoin::ChildOf, &block)
          }
        end
      end
    end
  end
end