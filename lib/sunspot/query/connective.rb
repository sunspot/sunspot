module Sunspot
  module Query
    module Connective #:nodoc:
      # 
      # Base class for connectives (conjunctions and disjunctions).
      #
      class Abstract < Scope
        def initialize(setup) #:nodoc:
          @setup = setup
          @components = []
        end

        # 
        # Connective as solr params.
        #
        def to_params #:nodoc:
          { :fq => to_boolean_phrase }
        end

        # 
        # Express the connective as a Lucene boolean phrase.
        #
        def to_boolean_phrase #:nodoc:
          if @components.length == 1
            @components.first.to_boolean_phrase
          else
            component_phrases = @components.map do |component|
              component.to_boolean_phrase
            end
            "(#{component_phrases.join(" #{connector} ")})"
          end
        end

        # 
        # Add a component to the connective. All components must implement the
        # #to_boolean_phrase method.
        #
        def add_component(component) #:nodoc:
          @components << component
        end
      end

      # 
      # Disjunctions combine their components with an OR operator.
      #
      class Disjunction < Abstract
        # 
        # Add a conjunction to the disjunction. This overrides the method in
        # the Scope class since scopes are implicitly conjunctive and thus
        # can return themselves as a conjunction. Inside a disjunction, however,
        # a conjunction must explicitly be created.
        #
        def add_conjunction
          @components << conjunction = Conjunction.new(setup)
          conjunction
        end

        private

        def connector
          'OR'
        end
      end

      # 
      # Conjunctions combine their components with an AND operator.
      #
      class Conjunction < Abstract
        private

        def connector
          'AND'
        end
      end
    end
  end
end
