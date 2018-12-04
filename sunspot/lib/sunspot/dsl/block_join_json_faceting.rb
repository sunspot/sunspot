module Sunspot
  module DSL
    module BlockJoin
      #
      # Module JsonFaceting includes methods that extends existing search DSL
      # with the BlockJoin Faceting feature over JSON API.
      #
      # Can be used as a mixin on the DSL class.
      #
      module JsonFaceting
        #
        # Performs a BlockJoin Faceting on child documents inside a search.
        #
        # ==== Examples
        #
        #   # Performs a search on all parents living in the United States
        #   # and facets on the age field of all their children.
        #   Sunspot.search(Parent) do
        #     with :lives_in, 'us'
        #     json_facet :age, block_join: (on_child(Child) do
        #       with :gender, 'male'
        #     end)
        #   end
        #
        # ==== Parameters
        #
        # type<Class>::
        #   Children type, needed for the inner filter block.
        #
        def on_child(type, &block)
          Sunspot::Util.ensure_child_documents_support
          {
            op: Sunspot::Query::BlockJoin::JsonFacet::ON_CHILDREN_OP,
            type: type,
            query: block_join_query(type, Sunspot::Query::BlockJoin::ParentWhich, &block)
          }
        end

        #
        # Performs a BlockJoin Faceting on parent documents inside a search.
        #
        # ==== Examples
        #
        #   # Performs a search on all reviews with more than 3 stars,
        #   # faceting on the genre of the movie of which those reviews belong to.
        #   Sunspot.search(Review) do
        #     with(:stars).greater_than(3)
        #     json_facet :genre, block_join: (on_parent(Movie) {})
        #   end
        #
        # Please note, the filter block on parents can even be empty.
        #
        # ==== Parameters
        #
        # type<Class>::
        #   Parent type, needed for the inner filter block.
        #
        def on_parent(type, &block)
          Sunspot::Util.ensure_child_documents_support
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