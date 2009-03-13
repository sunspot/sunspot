module Sunspot
  module DSL
    class Scope
      def initialize(query, negative = false)
        @query, @negative = query, negative
      end

      class <<self
        def implementation(field_names)
          implementations[Set.new(field_names)] ||= Class.new(self) do
            for field_name in field_names
              module_eval(<<-RUBY, __FILE__, __LINE__)
                def #{field_name}(value = nil)
                  unless value
                    RestrictionBuilder.new(#{field_name.to_s.inspect}, @query, @negative)
                  else
                    scope = @query.build_condition(#{field_name.to_s.inspect}, ::Sunspot::Restriction::EqualTo, value)
                    unless @negative
                      @query.add_scope(scope)
                    else
                      @query.add_negative_scope(scope)
                    end
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

        Sunspot::Restriction.names.each do |class_name|
          method_name = class_name.snake_case
          module_eval(<<-RUBY, __FILE__, __LINE__)
            def #{method_name}(value)
              scope = @query.build_condition(@field_name, Sunspot::Restriction::#{class_name}, value)
              unless @negative
                @query.add_scope(scope)
              else
                @query.add_negative_scope(scope)
              end
            end
          RUBY
        end
      end
    end
  end
end
