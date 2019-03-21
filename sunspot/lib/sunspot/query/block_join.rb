module Sunspot
  module Query
    #
    # Module BlockJoin provides classes that represent Block Join queries.
    #
    module BlockJoin
      #
      # Module Score contains all scoring methods that can be used
      # in a BlockJoin query result.
      #
      module Score
        NONE = 'none'.freeze
        AVG  = 'avg'.freeze
        MAX  = 'max'.freeze
        MIN  = 'min'.freeze
        TOT  = 'total'.freeze

        #
        # Ensures the input value is a valid +Score+ operation.
        #
        # ==== Parameters
        #
        # v<String>::
        #   The input value to be validated as +Score+.
        #
        def self.valid?(v)
          constants.include?(v) || constants.map(&method(:const_get)).include?(v)
        end
      end

      #
      # Abstract class to implement shared logic about BlockJoin queries.
      # Use +ChildOf+ or +ParentWhich+ classes when performing
      # actual BlockJoin queries.
      #
      class Abstract
        attr_reader :scope
        attr_reader :filter_query

        #
        # Initialize a new BlockJoin query.
        #
        # ==== Parameters
        #
        # scope<Sunspot::Query::Scope>::
        #   Selects the set of parent documents from which execute the query.
        #   Basically, it's the +allParents+ filter described
        #   in the reference guide.
        #
        # query<Sunspot::Query::StandardQuery>::
        #   Used as an additional filter to apply on the target document kind,
        #   evaluated after resolving the +allParents+ set.
        #   In a +child_of+ query, it's the +someParents+ filter.
        #   In a +parent_which+ query, it's the +someChildren+ filter.
        #
        # ==== Options
        #
        # :score<Sunspot::Query::BlockJoin::Scope>::
        #   Optional score operation to perform on matched documents in the query.
        #
        def initialize(scope, query, options = {})
          raise 'Provide a correct top-level scope!' unless scope? scope
          raise 'Filter query must be a correct query!' unless correct? query
          @filter_query = query
          @scope = scope
          add_scoring(options[:score]) unless options[:score].nil?
        end

        def score
          @score || Score::NONE
        end

        #
        # Returns the +allParents+ filter as string.
        #
        def all_parents_filter
          raise 'Implement in subclasses!'
        end

        #
        # Returns the secondary filter as a list of clauses.
        # If no additional filter has been specified, returns an empty list.
        #
        # Please note: to join all the secondary filter clauses, use this
        #
        #   query.secondary_filter.join(' AND ')
        #
        def secondary_filter
          return [] if filter_query.to_params[:q] == '*:*'
          ret = []
          ret << filter_query.fulltext.to_subquery[:q] unless filter_query.fulltext.nil?
          ret
        end

        private

        def add_scoring(op)
          if op.nil? || !Score.valid?(op)
            raise 'Invalid score value, see Sunspot::Query::BlockJoin::Score'
          end
          @score = op
        end

        def correct?(filter)
          filter.instance_of? StandardQuery
        end

        def scope?(scope)
          scope.instance_of? Scope
        end

        #
        # Generates the BlockJoin query parameter.
        #
        # ==== Parameters
        #
        # query_type<String>::
        #   The special kind of BlockJoin query to perform.
        #   Must be +child+ or +parent+.
        #
        # all_parents_key<String>::
        #   The subordinate parameter in the BlockJoin query.
        #   It will contain the +allParents+ filter.
        #   Must be +of+ (if +query_type+ is +child+),
        #   or +which+ (if +query_type+ is +parent+).
        #
        # ==== Returns
        #
        # String:: the BlockJoin query string to be added to the +:q+ filter.
        #
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

      #
      # Describes a BlockJoin Children Query.
      # For reference, https://lucene.apache.org/solr/guide/6_6/other-parsers.html#OtherParsers-BlockJoinChildrenQueryParser
      #
      class ChildOf < Abstract
        alias some_parents_filter secondary_filter

        def all_parents_filter
          # The scope of the initial query should give the 'allParents' filter,
          # to select which parents are used in the query.
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

        def to_params
          { q: render_query_string('child', 'of') }
        end
      end

      #
      # Describes a BlockJoin Parent Query.
      # For reference, https://lucene.apache.org/solr/guide/6_6/other-parsers.html#OtherParsers-BlockJoinParentQueryParser
      #
      class ParentWhich < Abstract
        alias some_children_filter secondary_filter

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

        def to_params
          { q: render_query_string('parent', 'which') }
        end
      end
    end
  end
end