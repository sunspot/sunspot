module Sunspot
  module Query #:nodoc:
    # TODO(ar3s3ru): add documentation
    module BlockJoin
      class Abstract
        attr_reader :all_parents_filter
        attr_reader :secondary_filter

        def initialize(parents_filters)
          raise 'Parents filter must be a correct filter!' unless correct? parents_filters
          @all_parents_filter = parents_filters
        end

        def add_secondary_filter(filter)
          raise 'Secondary filter must be a correct filter!' unless correct? filter
          @secondary_filter = filter
        end

        private

        def correct?(filter)
          filter.respond_to? :to_boolean_phrase
        end
      end

      class ChildOf < Abstract
        alias add_some_parents_filter add_secondary_filter

        def to_params
          query_string = "{!child of=\"#{all_parents_filter.to_boolean_phrase}\"}"
          query_string << secondary_filter.to_boolean_phrase unless secondary_filter.nil?
          { q: query_string }
        end
      end

      class ParentWhich < Abstract
        alias add_some_children_filter add_secondary_filter

        def to_params
          query_string = "{!parent which=\"#{all_parents_filter.to_boolean_phrase}\"}"
          query_string << secondary_filter.to_boolean_phrase unless secondary_filter.nil?
          { q: query_string }
        end
      end
    end
  end
end