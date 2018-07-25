module Sunspot
  module Query
    module BlockJoin #:nodoc:
      #
      # Implements BlockJoin Faceting feature on top of the JSON API.
      #
      class JsonFacet < AbstractJsonFieldFacet
        ON_CHILDREN_OP = 'blockChildren'.freeze
        ON_PARENTS_OP  = 'blockParent'.freeze
        FILTER_OP      = 'filter'.freeze

        #
        # Ensure that the requested operation is legal.
        # 
        def self.ensure_correct_operator(options)
          op = options[:op]
          unless [ON_CHILDREN_OP, ON_PARENTS_OP].include? op
            raise "Invalid block join faceting operator, must be '#{ON_CHILDREN_OP}' or '#{ON_PARENTS_OP}'"
          end
          op
        end

        #
        # Ensures that the input query is a BlockJoin query instance.
        #
        def self.ensure_correct_query(query)
          if !query.instance_of?(ChildOf) && !query.instance_of?(ParentWhich)
            raise 'Query must be Sunspot::Query::BlockJoin::ChildOf or ParentWhich'
          end
          query
        end

        #
        # Initializes a new BlockJoin Facet operation.
        #
        # ==== Parameters
        #
        # field<Sunspot::Field>::
        #   Document field on which we need faceting.
        #
        # setup<Sunspot::Setup>::
        #   Setup of the nested class (on which faceting is needed).
        #
        # query<Sunspot::Query::BlockJoin::>::
        #   BlockJoin query to execute in this faceting operation.
        #
        # ==== Options
        #
        # :op<String>::
        #   Specifies the operator to perform in the +domain+ clause
        #   of the +json.facet+ parameter.
        #
        def initialize(field, options, setup, query)
          super(field, options, setup)
          @query = BlockJoin::JsonFacet.ensure_correct_query(query)
          @operator = BlockJoin::JsonFacet.ensure_correct_operator(options)
        end

        def field_name_with_local_params
          {
            @field.name => {
              type: 'terms',
              field: @field.indexed_name,
              domain: {
                @operator => @query.all_parents_filter,
                FILTER_OP => generate_filter
              }
            }.merge!(init_params)
          }
        end

        private

        def generate_filter
          target_value = @query.secondary_filter.join(' AND ')
          target_value == '' ? '*:*' : target_value
        end
      end
    end
  end
end