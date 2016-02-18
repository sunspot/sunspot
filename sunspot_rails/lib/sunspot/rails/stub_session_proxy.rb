module Sunspot
  module Rails
    class StubSessionProxy
      attr_reader :original_session

      def initialize(original_session)
        @original_session = original_session
      end

      def batch
        yield
      end

      def index(*objects)
      end

      def index!(*objects)
      end

      def atomic_update(clazz, updates = {})
      end

      def atomic_update!(clazz, updates = {})
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

      def optimize
      end

      def dirty?
        false
      end

      def delete_dirty?
        false
      end

      def commit_if_dirty(soft_commit = false)
      end

      def commit_if_delete_dirty(soft_commit = false)
      end

      def commit(soft_commit = false)
      end

      def search(*types)
        Search.new
      end

      def new_search(*types)
        Search.new
      end

      def more_like_this(*args)
        Search.new
      end

      def new_more_like_this(*args)
        Search.new
      end

      class DataAccessorStub
        attr_accessor :include, :select
      end

      class Search

        def build
          self
        end

        def results
          PaginatedCollection.new
        end

        def hits(options = {})
          PaginatedCollection.new
        end
        alias_method :raw_results, :hits

        def total
          0
        end

        def facets
          []
        end

        def facet(name)
          FacetStub.new
        end

        def dynamic_facet(name)
          FacetStub.new
        end

        def data_accessor_for(klass)
          DataAccessorStub.new
        end

        def stats(name)
          StatsStub.new
        end

        def execute
          self
        end
      end


      class PaginatedCollection < Array

        def total_count
          0
        end
        alias :total_entries :total_count

        def current_page
          1
        end

        def per_page
          30
        end
        alias :limit_value :per_page

        def total_pages
          1
        end
        alias :num_pages :total_pages

        def first_page?
          true
        end

        def last_page?
          true
        end

        def previous_page
          nil
        end
        alias :prev_page :previous_page

        def next_page
          nil
        end

        def out_of_bounds?
          false
        end

        def offset
          0
        end

      end

      class FacetStub

        def rows
          []
        end

      end

      class StatsStub
        def min
          0
        end

        def max
          100
        end

        def count
          30
        end

        def sum
          500
        end

        def missing
          3
        end

        def sum_of_squares
          5000
        end

        def mean
          50
        end

        def standard_deviation
          20
        end

        def facets
          []
        end

        def facet(name)
          FacetStub.new
        end

      end

    end
  end
end
