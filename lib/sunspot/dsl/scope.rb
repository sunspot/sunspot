module Sunspot
  module DSL
    # 
    # This class presents an API for building restrictions in the query DSL. The
    # methods exposed are the snake-cased names of the classes defined in the
    # Restriction module, with the exception of Base and SameAs. All methods
    # take a single argument, which is the value to be applied to the
    # restriction.
    #
    class Restriction
      def initialize(field_name, query, negative)
        @field_name, @query, @negative = field_name, query, negative
      end

      Sunspot::Restriction.names.each do |class_name|
        method_name = class_name.snake_case
        module_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def #{method_name}(value)
            @query.add_restriction(@field_name, Sunspot::Restriction::#{class_name}, value, @negative)
          end
        RUBY
      end
    end
  end
end
