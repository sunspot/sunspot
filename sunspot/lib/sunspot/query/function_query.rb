module Sunspot
  module Query
    # 
    # Abstract class for function queries.
    #
    class AbstractFunctionQuery 
    end

    #
    # Function query which represents a constant.
    #
    class ConstantFunctionQuery < AbstractFunctionQuery
      def initialize(constant)
        @constant = constant
      end

      def to_s
        @constant.is_a?(String) ? %Q("#{@constant}") : %Q(#{@constant})
      end
    end

    #
    # Function query which represents a field.
    #
    class FieldFunctionQuery < AbstractFunctionQuery
      include RSolr::Char

      def initialize(field)
        @field = field
      end

      def to_s
        "#{escape(@field.indexed_name)}"
      end
    end

    #
    # Function query which represents an actual function invocation.
    # Takes a function name and arguments as parameters.
    # Arguments are in turn AbstractFunctionQuery objects.
    #
    class FunctionalFunctionQuery < AbstractFunctionQuery
      def initialize(function_name, function_args)
        @function_name, @function_args = function_name, function_args
      end

      def to_s
        params = @function_args.map { |arg| arg.to_s }.join(",")
        "#{@function_name}(#{params})"
      end
    end
  end
end
