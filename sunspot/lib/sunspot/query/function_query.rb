module Sunspot
  module Query
    # 
    # Abstract class for function queries.
    #
    class FunctionQuery 
      include RSolr::Char

      def ^(y)
        @boost_amount = y
        self
      end
    end

    #
    # Function query which represents a constant.
    #
    class ConstantFunctionQuery < FunctionQuery
      def initialize(constant)
        @constant = constant
      end

      def to_s
        Type.to_literal(@constant) << (@boost_amount ? "^#{@boost_amount}" : "")
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
        "#{escape(@field.indexed_name)}" << (@boost_amount ? "^#{@boost_amount}" : "")
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
        "#{@function_name}(#{params})" << (@boost_amount ? "^#{@boost_amount}" : "")
      end
    end
  end
end
