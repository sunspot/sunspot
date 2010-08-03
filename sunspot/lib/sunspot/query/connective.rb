module Sunspot
  module Query
    module Connective #:nodoc:all
      # 
      # Base class for connectives (conjunctions and disjunctions).
      #
      class Abstract
        include Filter

        def initialize(negated = false) #:nodoc:
          @negated = negated
          @components = []
        end

        # 
        # Add a restriction to the connective.
        #
        def add_restriction(negated, field, restriction_type, *value)
          add_component(restriction_type.new(negated, field, *value))
        end

        # 
        # Add a shorthand restriction; the restriction type is determined by
        # the value.
        #
        def add_shorthand_restriction(negated, field, value)
          restriction_type =
            case value
            when Array then Restriction::AnyOf
            when Range then Restriction::Between
            else Restriction::EqualTo
            end
          add_restriction(negated, field, restriction_type, value)
        end

        # 
        # Add a positive restriction. The restriction will match all
        # documents who match the terms fo the restriction.
        #
        def add_positive_restriction(field, restriction_type, value)
          add_restriction(false, field, restriction_type, value)
        end

        # 
        # Add a positive shorthand restriction (see add_shorthand_restriction)
        #
        def add_positive_shorthand_restriction(field, value)
          add_shorthand_restriction(false, field, value)
        end

        # 
        # Add a negated restriction. The added restriction will match all
        # documents who do not match the terms of the restriction.
        #
        def add_negated_restriction(field, restriction_type, value)
          add_restriction(true, field, restriction_type, value)
        end

        # 
        # Add a negated shorthand restriction (see add_shorthand_restriction)
        #
        def add_negated_shorthand_restriction(field, value)
          add_shorthand_restriction(true, field, value)
        end

        # 
        # Add a new conjunction and return it.
        #
        def add_conjunction
          add_component(Conjunction.new)
        end

        # 
        # Add a new disjunction and return it.
        #
        def add_disjunction
          add_component(Disjunction.new)
        end

        # 
        # Add an arbitrary component to the conjunction, and return it.
        # The component must respond to #to_boolean_phrase
        #
        def add_component(component)
          @components << component
          component
        end

        # 
        # Express the connective as a Lucene boolean phrase.
        #
        def to_boolean_phrase #:nodoc:
          unless @components.empty?
            phrase =
              if @components.length == 1
                @components.first.to_boolean_phrase
              else
                component_phrases = @components.map do |component|
                  component.to_boolean_phrase
                end
                "(#{component_phrases.join(" #{connector} ")})"
              end
            if negated?
              "-#{phrase}"
            else
              phrase
            end
          end
        end

        # 
        # Connectives can be negated during the process of denormalization that
        # is performed when a disjunction contains a negated component. This
        # method conforms to the duck type for all boolean query components.
        #
        def negated?
          @negated
        end

        # 
        # Returns a new connective that's a negated version of this one.
        #
        def negate
          negated = self.class.new(!negated?)
          @components.each do |component|
            negated.add_component(component)
          end
          negated
        end
      end

      # 
      # Disjunctions combine their components with an OR operator.
      #
      class Disjunction < Abstract
        class <<self
          def inverse
            Conjunction
          end
        end

        # 
        # Express this disjunction as a Lucene boolean phrase
        #
        def to_boolean_phrase
          if @components.any? { |component| component.negated? }
            denormalize.to_boolean_phrase
          else
            super
          end
        end

        # 
        # No-op - this is already a disjunction
        #
        def add_disjunction
          self
        end

        private

        def connector
          'OR'
        end

        # 
        # If a disjunction contains negated components, it must be
        # "denormalized", because the Lucene parser interprets any negated
        # boolean phrase using AND semantics (this isn't a bug, it's just a
        # subtlety of how Lucene parses queries). So, per DeMorgan's law we
        # create a negated conjunction and add to it all of our components,
        # negated themselves, which creates a query whose Lucene semantics are
        # in line with our intentions.
        #
        def denormalize
          denormalized = self.class.inverse.new(!negated?)
          @components.each do |component|
            denormalized.add_component(component.negate)
          end
          denormalized
        end
      end

      # 
      # Conjunctions combine their components with an AND operator.
      #
      class Conjunction < Abstract
        class <<self
          def inverse
            Disjunction
          end
        end

        def add_conjunction
          self
        end

        private

        def connector
          'AND'
        end
      end
    end
  end
end
