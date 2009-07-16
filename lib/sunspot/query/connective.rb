module Sunspot
  module Query
    #TODO document
    module Connective
      class Abstract < Scope
        def initialize(setup)
          @setup = setup
          @components = []
        end

        def add_conjunction
          @components << conjunction = Conjunction.new(@setup)
          conjunction
        end

        def to_params
          { :fq => to_boolean_phrase }
        end

        def to_boolean_phrase
          component_phrases = @components.map do |component|
            component.to_boolean_phrase
          end
          "(#{component_phrases.join(" #{connector} ")})"
        end

        def add_component(component)
          @components << component
        end
      end

      class Disjunction < Abstract
        private

        def connector
          'OR'
        end
      end

      class Conjunction < Abstract
        private

        def connector
          'AND'
        end
      end
    end
  end
end
