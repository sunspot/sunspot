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

      def initialize(scope, setup) #:nodoc:
        @scope, @setup = scope, setup
      end

      # 
      # Build a positive restriction. With one argument, this method returns
      # another DSL object which presents methods for attaching various
      # restriction types. With two arguments, this creates a shorthand
      # restriction: if the second argument is a scalar, an equality restriction
      # is created; if it is a Range, a between restriction will be created; and
      # if it is an Array, an any_of restriction will be created.
      #
      # ==== Parameters
      #
      # field_name<Symbol>:: Name of the field on which to place the restriction
      # value<Object,Range,Array>::
      #   If passed, creates an equality, range, or any-of restriction based on
      #   the type of value passed.
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
      # Restrict by range:
      #
      #   Sunspot.search do
      #     with(:average_rating, 3.0..5.0)
      #   end
      #
      # Restrict by a set of allowed values:
      #
      #   Sunspot.search do
      #     with(:category_ids, [1, 5, 9])
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
          DSL::Restriction.new(@setup.field(field_name.to_sym), @scope, false)
        else
          @scope.add_positive_shorthand_restriction(@setup.field(field_name), value)
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
            DSL::Restriction.new(@setup.field(field_name.to_sym), @scope, true)
          else
            @scope.add_negated_shorthand_restriction(@setup.field(field_name.to_sym), value)
          end
        else
          instances = args
          instances.flatten.each do |instance|
            @scope.add_negated_restriction(
              IdField.instance,
              Sunspot::Query::Restriction::EqualTo,
              Sunspot::Adapters::InstanceAdapter.adapt(instance).index_id
            )
          end
        end
      end

      # 
      # Create a disjunction, scoping the results to documents that match any
      # of the enclosed restrictions.
      #
      # ==== Example
      #
      #   Sunspot.search(Post) do
      #     any_of do
      #       with(:expired_at).greater_than Time.now
      #       with :expired_at, nil
      #     end
      #   end
      #
      # This will return all documents who either have an expiration time in the
      # future, or who do not have any expiration time at all.
      #
      def any_of(&block)
        disjunction = @scope.add_disjunction
        Util.instance_eval_or_call(Scope.new(disjunction, @setup), &block)
        disjunction
      end

      # 
      # Create a conjunction, scoping the results to documents that match all of
      # the enclosed restrictions. When called from the top level of a search
      # block, this has no effect, but can be useful for grouping a conjunction
      # inside a disjunction.
      #
      # ==== Example
      #
      #   Sunspot.search(Post) do
      #     any_of do
      #       with(:blog_id, 1)
      #       all_of do
      #         with(:blog_id, 2)
      #         with(:category_ids, 3)
      #       end
      #     end
      #   end
      #
      def all_of(&block)
        conjunction = @scope.add_conjunction
        Util.instance_eval_or_call(Scope.new(conjunction, @setup), &block)
        conjunction
      end

      #
      # Apply restrictions, facets, and ordering to dynamic field instances.
      # The block API is implemented by Sunspot::DSL::FieldQuery, which is a
      # superclass of the Query DSL (thus providing a subset of the API, in
      # particular only methods that refer to particular fields).
      # 
      # ==== Parameters
      # 
      # base_name<Symbol>:: The base name for the dynamic field definition
      #
      # ==== Example
      #
      #   Sunspot.search Post do
      #     dynamic :custom do
      #       with :cuisine, 'Pizza'
      #       facet :atmosphere
      #       order_by :chef_name
      #     end
      #   end
      #
      def dynamic(base_name, &block)
        Sunspot::Util.instance_eval_or_call(
          Scope.new(@scope, @setup.dynamic_field_factory(base_name)),
          &block
        )
      end

      # 
      # Apply scope-type restrictions on fulltext fields. In certain situations,
      # it may be desirable to place logical restrictions on text fields.
      # Remember that text fields are tokenized; your mileage may very.
      #
      # The block works exactly like a normal scope, except that the field names
      # refer to text fields instead of attribute fields.
      # 
      # === Example
      #
      #   Sunspot.search(Post) do
      #     text_fields do
      #       with :body, nil
      #     end
      #   end
      #
      # This will return all documents that do not have a body.
      #
      def text_fields(&block)
        Sunspot::Util.instance_eval_or_call(
          Scope.new(@scope, TextFieldSetup.new(@setup)),
          &block
        )
      end
    end
  end
end
