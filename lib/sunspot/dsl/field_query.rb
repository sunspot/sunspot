module Sunspot
  module DSL
    # 
    # Provides an API for areas of the query DSL that operate on specific
    # fields. This functionality is provided by the query DSL and the dynamic
    # query DSL.
    #
    class FieldQuery < Scope
      def initialize(query, setup)
        @query = query
        super(query.scope, setup)
      end

      # Specify the order that results should be returned in. This method can
      # be called multiple times; precedence will be in the order given.
      #
      # ==== Parameters
      #
      # field_name<Symbol>:: the field to use for ordering
      # direction<Symbol>:: :asc or :desc (default :asc)
      #
      def order_by(field_name, direction = nil)
        sort =
          if special = Sunspot::Query::Sort.special(field_name)
            special.new(direction)
          else
            Sunspot::Query::Sort::FieldSort.new(
              @setup.field(field_name), direction
            )
          end
        @query.add_sort(sort)
      end

      # 
      # DEPRECATED Use <code>order_by(:random)</code>
      #
      def order_by_random
        order_by(:random)
      end

      # Request facets on the given field names. If the last argument is a hash,
      # the given options will be applied to all specified fields. See
      # Sunspot::Search#facet and Sunspot::Facet for information on what is
      # returned.
      #
      # ==== Parameters
      #
      # field_names...<Symbol>:: fields for which to return field facets
      #
      # ==== Options
      #
      # :sort<Symbol>::
      #   Either :count (values matching the most terms first) or :index (lexical)
      # :limit<Integer>::
      #   The maximum number of facet rows to return
      # :minimum_count<Integer>::
      #   The minimum count a facet row must have to be returned
      # :zeros<Boolean>::
      #   Return facet rows for which there are no matches (equivalent to
      #   :minimum_count => 0). Default is false.
      #
      def facet(*field_names, &block)
        if block
          options =
            if field_names.last.is_a?(Hash)
              field_names.pop
            else
              {}
            end
          if field_names.length != 1
            raise(
              ArgumentError,
              "wrong number of arguments (#{field_names.length} for 1)"
            )
          end
          name = field_names.first
          DSL::QueryFacet.new(@query.add_query_facet(name, options), @setup).instance_eval(&block)
        else
          options = 
            if field_names.last.is_a?(Hash)
              field_names.pop
            else
              {}
            end
          for field_name in field_names
            @query.add_field_facet(@setup.field(field_name), options)
          end
        end
      end

      def dynamic(base_name, &block)
        Sunspot::Util.instance_eval_or_call(
          FieldQuery.new(@query, @setup.dynamic_field_factory(base_name)),
          &block
        )
      end
    end
  end
end
