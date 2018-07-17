module Sunspot
  module Query #:nodoc:
    # TODO(ar3s3ru): add documentation
    module BlockJoin
      class Abstract
        attr_reader :filter_query

        def initialize(query, options = {})
          raise 'Filter query must be a correct query!' unless correct? query
          @filter_query = query
          add_scoring(options[:score]) unless options[:score].nil?
        end

        def add_scoring(op)
          if op.nil? || !Score.valid?(op)
            raise 'Invalid score value, see Sunspot::Query::BlockJoin::Score'
          end
          @score = op
        end

        def score
          @score || Score::NONE
        end

        private

        def correct?(filter)
          filter.instance_of? StandardQuery
        end

        def render_query_string(query_type, all_parents_key)
          # The scope of the initial query should give the 'allParents' filter,
          # to select which parents are used in the query.
          # TODO(ar3s3ru): test this shit
          all_parents = filter_query.to_params[:fq]
          filter = filter_query.to_params[:q]

          raise 'allParents filter must be non-empty!' if all_parents.nil?
          parents_length = all_parents.length
          if parents_length > 1
            # We must put additional filters in the 'q' query
            additional_filters = all_parents.slice!(1, parents_length - 1)
            # Use only the type constraint for parents
            all_parents = all_parents[0]
            filter = [] if filter == '*:*'
            filter << additional_filters
            filter.flatten!
          end

          query_string = "{!#{query_type} #{all_parents_key}=\"#{all_parents}\""
          query_string << " score=#{score}" unless score.nil?
          query_string << '}'
          query_string << filter.join(' ') unless filter.nil?
          query_string
        end
      end

      class ChildOf < Abstract
        def to_params
          { q: render_query_string('child', 'of') }
        end
      end

      class ParentWhich < Abstract
        def to_params
          { q: render_query_string('parent', 'which') }
        end
      end

      module Score
        NONE = 'none'.freeze
        AVG  = 'avg'.freeze
        MAX  = 'max'.freeze
        MIN  = 'min'.freeze
        TOT  = 'total'.freeze

        def self.valid?(v)
          constants.include?(v) || constants.map(&method(:const_get)).include?(v)
        end
      end
    end
  end
end