module Sunspot
  module Query
    # 
    # The Scope class encapsulates a set of restrictions that scope search
    # results (as well as query facets rows). This class's API is exposed by
    # Query::Query and Query::QueryFacetRow.
    # 
    class Scope
      # 
      # Add a restriction to the query.
      # 
      # ==== Parameters
      #
      # field_name<Symbol>:: Name of the field to which the restriction applies
      # restriction_type<Class,Symbol>::
      #   Subclass of Sunspot::Query::Restriction::Base, or snake_cased name as symbol
      #   (e.g., +:equal_to+)
      # value<Object>::
      #   Value against which the restriction applies (e.g. less_than(2) has a
      #   value of 2)
      # negated::
      #   Whether this restriction should be negated (use add_negated_restriction)
      #
      def add_restriction(field_name, restriction_type, value, negated = false)
        if restriction_type.is_a?(Symbol)
          restriction_type = Restriction[restriction_type]
        end
        add_component(
          restriction = restriction_type.new(
            build_field(field_name), value, negated
          )
        )
        restriction
      end

      # 
      # Add a negated restriction to the query. The restriction will be taken as
      # the opposite of its usual meaning (e.g., an :equal_to restriction will
      # be "not equal to".
      #
      # ==== Parameters
      #
      # field_name<Symbol>:: Name of the field to which the restriction applies
      # restriction_type<Class>::
      #   Subclass of Sunspot::Query::Restriction::Base to instantiate
      # value<Object>::
      #   Value against which the restriction applies (e.g. less_than(2) has a
      #   value of 2)
      #
      def add_negated_restriction(field_name, restriction_type, value)
        add_restriction(field_name, restriction_type, value, true)
      end

      # 
      # Add a disjunction to the scope. The disjunction can then take a set of
      # restrictions, which are combined with OR semantics.
      #
      # ==== Returns
      #
      # Connective::Disjunction:: New disjunction
      #
      def add_disjunction
        add_component(disjunction = Connective::Disjunction.new(setup))
        disjunction
      end

      # 
      # Add a conjunction to the scope. In most cases, this will simply return
      # the Scope object itself, since scopes by default combine their
      # restrictions with OR semantics. The Connective::Disjunction class
      # overrides this method to return a Connective::Conjunction.
      #
      # ==== Returns
      #
      # Scope:: Self or another scope with conjunctive semantics.
      #
      def add_conjunction
        self
      end
      
      #
      # Exclude a particular instance from the search results
      #
      # ==== Parameters
      #
      # instance<Object>:: instance to exclude from results
      #
      def exclude_instance(instance)
        add_component(Restriction::SameAs.new(instance, true))
      end

      # 
      # Generate a DynamicQuery instance for the given base name.
      # This gives you access to a subset of the Query API but the operations
      # apply to dynamic fields inside the dynamic field definition specified
      # by +base_name+.
      # 
      # ==== Parameters
      # 
      # base_name<Symbol>::
      #   Base name of the dynamic field definition to use in the dynamic query
      #   operations
      #
      # ==== Returns
      #
      # DynamicQuery::
      #   Instance providing dynamic query functionality for the given field
      #   definitions.
      #
      def dynamic_query(base_name)
        DynamicQuery.new(setup.dynamic_field_factory(base_name), self)
      end

      # 
      # Determine which restriction type to add based on the type of the value.
      # Used to interpret query conditions passed as a hash, as well as the
      # short-form DSL::Scope#with method.
      #
      # ==== Parameters
      #
      # field_name<Symbol>:: Name of the field on which to apply the restriction
      # value<Object,Array,Range>:: Value to which to apply to the restriction
      #--
      # negated<Boolean>:: Whether to negate the restriction.
      #
      def add_shorthand_restriction(field_name, value, negated = false) #:nodoc:
        restriction_type =
          case value
          when Range
            Restriction::Between
          when Array
            Restriction::AnyOf
          else
            Restriction::EqualTo
          end
        add_restriction(field_name, restriction_type, value, negated)
      end

      # 
      # Add a negated shorthand restriction. See #add_shorthand_restriction
      #
      def add_negated_shorthand_restriction(field_name, value)
        add_shorthand_restriction(field_name, value, true)
      end

      private

      # 
      # Build a field with the given field name. Subclasses may override this
      # method.
      #
      def build_field(field_name)
        setup.field(field_name)
      end

      # 
      # Return a setup object which can return a field object given a name.
      # Subclasses may override this method.
      #
      def setup
        @setup
      end
    end
  end
end
