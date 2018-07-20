module Sunspot
  module Query #:nodoc:
    # TODO(ar3s3ru): add documentation
    module BlockJoin
      class Abstract
        attr_reader :scope
        attr_reader :filter_query

        def initialize(scope, query, options = {})
          raise 'Provide a correct top-level scope!' unless scope? scope
          raise 'Filter query must be a correct query!' unless correct? query
          @filter_query = query
          @scope = scope
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

        def scope?(scope)
          scope.instance_of? Scope
        end

        def all_parents_filter
          raise 'Implement in subclasses!'
        end

        def secondary_filter
          return [] if filter_query.to_params[:q] == '*:*'
          filter_query.to_params[:q]
        end

        def render_query_string(query_type, all_parents_key)
          all_parents = all_parents_filter
          filter      = secondary_filter

          query_string = "{!#{query_type} #{all_parents_key}=\"#{all_parents}\""
          query_string << " score=#{score}" unless score.nil?
          query_string << '}'
          query_string << filter.join(' AND ') unless filter.nil?
          query_string
        end
      end

      class ChildOf < Abstract
        def to_params
          { q: render_query_string('child', 'of') }
        end

        private

        def all_parents_filter
          # The scope of the initial query should give the 'allParents' filter,
          # to select which parents are used in the query.
          # TODO(ar3s3ru): test this shit
          fq = filter_query.to_params[:fq]
          raise 'allParents filter must be non-empty!' if fq.nil?
          fq[0] # Type filter used by Sunspot
        end

        def secondary_filter
          fq = filter_query.to_params[:fq]
          q  = super
          # Add other constraints on parents' filter query to someParents filter.
          q << fq.slice(1, fq.length - 1) if fq.length > 1
          q.flatten!
          q
        end
      end

      class ParentWhich < Abstract
        def to_params
          { q: render_query_string('parent', 'which') }
        end

        private

        def all_parents_filter
          # Use top-level scope (on parent type) as allParents filter.
          scope.to_params[:fq].flatten.join(' AND ')
        end

        def secondary_filter
          q = super
          # Everything in the subquery is related to children: use those
          # filters as 'someChildren' field.
          q << filter_query.to_params[:fq]
          q.flatten!
          q
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