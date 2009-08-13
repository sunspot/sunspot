module Sunspot
  module Query
    module Connective #:nodoc:
      # 
      # Base class for connectives (conjunctions and disjunctions).
      #
      class Abstract < Scope
        def initialize(setup, negated = false) #:nodoc:
          super(setup)
          @negated = negated
        end

        # 
        # Connective as solr params.
        #
        def to_params #:nodoc:
          if boolean_phrase = to_boolean_phrase
            { :fq => to_boolean_phrase }
          else
            {}
          end
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
          negated = self.class.new(@setup, !negated?)
          for component in @components
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
        # Add a conjunction to the disjunction. This overrides the method in
        # the Scope class since scopes are implicitly conjunctive and thus
        # can return themselves as a conjunction. Inside a disjunction, however,
        # a conjunction must explicitly be created.
        #
        def add_conjunction
          @components << conjunction = Conjunction.new(@setup)
          conjunction
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
          denormalized = self.class.inverse.new(@setup, !negated?)
          for component in @components
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

        private

        def connector
          'AND'
        end
      end
    end
  end
end
