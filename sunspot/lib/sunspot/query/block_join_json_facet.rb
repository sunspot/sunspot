module Sunspot
  module Query
    module BlockJoin
      # TODO(ar3s3ru): add documentation
      class JsonFacet < AbstractJsonFieldFacet
        ON_CHILDREN_OP = 'blockChildren'.freeze
        ON_PARENTS_OP  = 'blockParent'.freeze
        FILTER_OP      = 'filter'.freeze

        def self.ensure_correct_operator(options)
          op = options[:op]
          unless [ON_CHILDREN_OP, ON_PARENTS_OP].include? op
            raise "Invalid block join faceting operator, must be '#{ON_CHILDREN_OP}' or '#{ON_PARENTS_OP}'"
          end
          op
        end

        def self.ensure_correct_query(query)
          if !query.instance_of?(ChildOf) && !query.instance_of?(ParentWhich)
            raise 'Query must be Sunspot::Query::BlockJoin::ChildOf or ParentWhich'
          end
          query
        end

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