module Sunspot
  module Query
    # 
    # Abstract class for function queries.
    #
    class FunctionQuery 
      include RSolr::Char
    end

    #
    # Function query which represents a constant.
    #
    class ConstantFunctionQuery < FunctionQuery
      def initialize(constant)
        @constant = constant
      end

      def to_s
        Type.to_literal(@constant)
      end
    end

    #
    # Function query which represents a field.
    #
    class FieldFunctionQuery < FunctionQuery
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
    # Arguments are in turn FunctionQuery objects.
    #
    class FunctionalFunctionQuery < FunctionQuery
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
