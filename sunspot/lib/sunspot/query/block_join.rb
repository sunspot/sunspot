module Sunspot
  module Query #:nodoc:
    # TODO(ar3s3ru): add documentation
    module BlockJoin
      class ChildOf < Abstract
        alias add_some_parents_filter add_secondary_filter

        def to_boolean_phrase
          "{!child of=\"#{all_parents_filters}\"}#{secondary_filter}"
        end
      end

      class ParentWhich < Abstract
        alias add_some_children_filter add_secondary_filter

        def to_boolean_phrase
          "{!parent which=\"#{all_parents_filters}\"}#{secondary_filter}"
        end
      end

      private

      class Abstract
        DEFAULT_PARENTS_FILTER = '*.*'.freeze

        include ::Sunspot::Query::Filter

        attr_reader :all_parents_filters
        attr_reader :secondary_filter

        def initialize(parents_filters)
          @all_parents_filters = parents_filters | DEFAULT_PARENTS_FILTER
        end

        def add_secondary_filter(filter)
          @secondary_filter = filter
        end
      end
    end
  end
end