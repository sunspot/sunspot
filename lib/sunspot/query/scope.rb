module Sunspot
  module Query
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

      def add_negated_shorthand_restriction(field_name, value)
        add_shorthand_restriction(field_name, value, true)
      end

      #TODO document
      def add_disjunction
        @components << disjunction = Connective::Disjunction.new(@setup)
        disjunction
      end

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
        DynamicQuery.new(@setup.dynamic_field_factory(base_name), self)
      end

      private

      def build_field(field_name)
        @setup.field(field_name)
      end
    end
  end
end
