module Sunspot
  module DSL
    # 
    # Provides an API for areas of the query DSL that operate on specific
    # fields. This functionality is provided by the query DSL and the dynamic
    # query DSL.
    #
    class FieldQuery < Scope
      def initialize(search, query, setup) #:nodoc:
        @search, @query = search, query
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
      # :extra<Symbol,Array>::
      #   One or more of :any and :none. :any returns a facet row with a count
      #   of all matching documents that have some value for this field. :none
      #   returns a facet row with a count of all matching documents that have
      #   no value for this field. The facet row(s) corresponding to the extras
      #   have a value of the symbol passed.
      #
      def facet(*field_names, &block)
        options = Sunspot::Util.extract_options_from(field_names)

        if block
          if field_names.length != 1
            raise(
              ArgumentError,
              "wrong number of arguments (#{field_names.length} for 1)"
            )
          end
          search_facet = @search.add_query_facet(field_names.first, options)
          Sunspot::Util.instance_eval_or_call(
            QueryFacet.new(@query, @setup, search_facet),
            &block
          )
        elsif options[:only]
          field_names.each do |field_name|
            field = @setup.field(field_name)
            search_facet = @search.add_field_facet(field, options)
            Util.Array(options[:only]).each do |value|
              facet = Sunspot::Query::QueryFacet.new
              facet.add_restriction(field, Sunspot::Query::Restriction::EqualTo, value)
              @query.add_query_facet(facet)
              search_facet.add_row(value, facet.to_boolean_phrase)
            end
          end
        else
          field_names.each do |field_name|
            search_facet = nil
            field = @setup.field(field_name)
            facet =
              if options[:time_range]
                unless field.type == Sunspot::Type::TimeType
                  raise(
                    ArgumentError,
                    ':time_range can only be specified for Date or Time fields'
                  )
                end
                search_facet = @search.add_date_facet(field, options)
                Sunspot::Query::DateFieldFacet.new(field, options)
              else
                search_facet = @search.add_field_facet(field)
                Sunspot::Query::FieldFacet.new(field, options)
              end
            @query.add_field_facet(facet)
            Util.Array(options[:extra]).each do |extra|
              extra_facet = Sunspot::Query::QueryFacet.new
              case extra
              when :any
                extra_facet.add_negated_restriction(
                  field,
                  Sunspot::Query::Restriction::EqualTo,
                  nil
                )
              when :none
                extra_facet.add_restriction(
                  field,
                  Sunspot::Query::Restriction::EqualTo,
                  nil
                )
              else
                raise(
                  ArgumentError,
                  "Allowed values for :extra are :any and :none"
                )
              end
              search_facet.add_row(extra, extra_facet.to_boolean_phrase)
              @query.add_query_facet(extra_facet)
            end
          end
        end
      end

      def dynamic(base_name, &block)
        dynamic_field_factory = @setup.dynamic_field_factory(base_name)
        Sunspot::Util.instance_eval_or_call(
          FieldQuery.new(@search, @query, dynamic_field_factory),
          &block
        )
      end
    end
  end
end
