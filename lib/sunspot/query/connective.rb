module Sunspot
  class Query
    #TODO document
    module Connective
      class Abstract
        def initialize(setup)
          @setup = setup
          @components = []
        end

        def add_restriction(field_name, restriction_type, value, negated = false)
          if restriction_type.is_a?(Symbol)
            restriction_type = Restriction[restriction_type]
          end
          @components << restriction = restriction_type.new(
            @setup.field(field_name), value, negated
          )
          restriction
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
