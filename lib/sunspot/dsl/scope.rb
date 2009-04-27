module Sunspot
  module DSL
    # TODO document after refactor
    class Scope
      def initialize(query, negative = false)
        @query, @negative = query, negative
      end

      class <<self
        def implementation(field_names)
          implementations[Set.new(field_names)] ||= Class.new(self) do
            for field_name in field_names
              module_eval(<<-RUBY, __FILE__, __LINE__ + 1)
                def #{field_name}(value = nil)
                  unless value
                    RestrictionBuilder.new(#{field_name.to_s.inspect}, @query, @negative)
                  else
                    @query.add_restriction(#{field_name.to_s.inspect}, Restriction::EqualTo, value, @negative)
                  end
                end
              RUBY
            end
          end
        end

        private

        def implementations
          @implementations ||= {}
        end
      end

      class RestrictionBuilder
        def initialize(field_name, query, negative)
          @field_name, @query, @negative = field_name, query, negative
        end

        Restriction.names.each do |class_name|
          method_name = class_name.snake_case
          module_eval(<<-RUBY, __FILE__, __LINE__ + 1)
            def #{method_name}(value)
              @query.add_restriction(@field_name, Restriction::#{class_name}, value, @negative)
            end
          RUBY
        end
      end
    end
  end
end
