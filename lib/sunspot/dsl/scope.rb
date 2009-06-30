module Sunspot
  module DSL #:nodoc:
    # 
    # This DSL presents methods for constructing restrictions and other query
    # elements that are specific to fields. As well as being a superclass of
    # Sunspot::DSL::Query, which presents the main query block, this DSL class
    # is also used directly inside the #dynamic() block, which only allows
    # operations on specific fields.
    #
    class Scope
      NONE = Object.new

      def initialize(query) #:nodoc:
        @query = query
      end

      # 
      # Build a positive restriction. With one argument, this method returns
      # another DSL object which presents methods for attaching various
      # restriction types. With two arguments, acts as a shorthand for creating
      # an equality restriction.
      #
      # ==== Parameters
      #
      # field_name<Symbol>:: Name of the field on which to place the restriction
      # value<Symbol>::
      #   If passed, creates an equality restriction with this value
      #
      # ==== Returns
      #
      # Sunspot::DSL::Query::Restriction::
      #   Restriction DSL object (if only one argument is passed)
      #
      # ==== Examples
      #
      # An equality restriction:
      #
      #   Sunspot.search do
      #     with(:blog_id, 1)
      #   end
      # 
      # Other restriction types:
      #
      #   Sunspot.search(Post) do
      #     with(:average_rating).greater_than(3.0)
      #   end
      #
      def with(field_name, value = NONE)
        if value == NONE
          DSL::Restriction.new(field_name.to_sym, @query, false)
        else
          @query.add_restriction(field_name, Sunspot::Query::Restriction::EqualTo, value, false)
        end
      end

      # 
      # Build a negative restriction (exclusion). This method can take three
      # forms: equality exclusion, exclusion by another restriction, or identity
      # exclusion. The first two forms work the same way as the #with method;
      # the third excludes a specific instance from the search results.
      #
      # ==== Parameters (exclusion by field value)
      #
      # field_name<Symbol>:: Name of the field on which to place the exclusion
      # value<Symbol>::
      #   If passed, creates an equality exclusion with this value
      #
      # ==== Parameters (exclusion by identity)
      #
      # args<Object>...::
      #   One or more instances that should be excluded from the results
      #
      # ==== Examples
      #
      # An equality exclusion:
      #
      #   Sunspot.search(Post) do
      #     without(:blog_id, 1)
      #   end
      # 
      # Other restriction types:
      #
      #   Sunspot.search(Post) do
      #     without(:average_rating).greater_than(3.0)
      #   end
      #
      # Exclusion by identity:
      #
      #   Sunspot.search(Post) do
      #     without(some_post_instance)
      #   end
      #
      def without(*args)
        case args.first
        when String, Symbol
          field_name = args[0]
          value = args.length > 1 ? args[1] : NONE
          if value == NONE
            DSL::Restriction.new(field_name.to_sym, @query, true)
          else
            @query.add_negated_restriction(field_name, Sunspot::Query::Restriction::EqualTo, value)
          end
        else
          instances = args
          for instance in instances.flatten
            @query.exclude_instance(instance)
          end
        end
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
        @query.order_by(field_name, direction)
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
      def facet(*field_names)
        options = 
          if field_names.last.is_a?(Hash)
            field_names.pop
          end
        for field_name in field_names
          @query.add_field_facet(field_name, options)
        end
      end
    end
  end
end
