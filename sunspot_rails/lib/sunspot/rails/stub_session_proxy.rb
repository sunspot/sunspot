module Sunspot
  module Rails
    class StubSessionProxy
      attr_reader :original_session

      def initialize(original_session)
        @original_session = original_session
      end

      def index(*objects)
      end

      def index!(*objects)
      end

      def remove(*objects)
      end

      def remove!(*objects)
      end

      def remove_by_id(clazz, id)
      end

      def remove_by_id!(clazz, id)
      end

      def remove_all(clazz = nil)
      end

      def remove_all!(clazz = nil)
      end

      def dirty?
        false
      end

      def delete_dirty?
        false
      end

      def commit_if_dirty
      end

      def commit_if_delete_dirty
      end

      def commit
      end

      def search(*types)
        Search.new
      end

      def new_search(*types)
        Search.new
      end

      class Search
        def build
          self
        end

        def results
          []
        end

        def hits(options = {})
          []
        end

        def total
          0
        end

        def facet(name)
        end

        def dynamic_facet(name)
        end

        def execute
          self
        end
      end
    end
  end
end
