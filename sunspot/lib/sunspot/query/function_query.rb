module Sunspot
  module Query
    # 
    # Abstract class for function queries.
    #
    class FunctionQuery
      attr_reader :boost_amount

      def ^(y)
        @boost_amount = y
        self
      end

      def ==(other)
        @boost_amount == other.boost_amount
      end
    end

    #
    # Function query which represents a constant.
    #
    class ConstantFunctionQuery < FunctionQuery
      attr_reader :constant

      def initialize(constant)
        @constant = constant
      end

      def to_s
        Type.to_literal(@constant) << (@boost_amount ? "^#{@boost_amount}" : "")
      end

      def ==(other)
        super and @constant == other.constant
      end
    end

    #
    # Function query which represents a field.
    #
    class FieldFunctionQuery < FunctionQuery
      attr_reader :field

      def initialize(field)
        @field = field
      end

      def to_s
        "#{Util.escape(@field.indexed_name)}" << (@boost_amount ? "^#{@boost_amount}" : "")
      end

      def ==(other)
        super and @field == other.field
      end
    end

    #
    # Function query which represents an actual function invocation.
    # Takes a function name and arguments as parameters.
    # Arguments are in turn FunctionQuery objects.
    #
    class FunctionalFunctionQuery < FunctionQuery
      attr_reader :function_name, :function_args

      def initialize(function_name, function_args)
        @function_name, @function_args = function_name, function_args
      end

      def to_s
        params = @function_args.map { |arg| arg.to_s }.join(",")
        "#{@function_name}(#{params})" << (@boost_amount ? "^#{@boost_amount}" : "")
      end

      def ==(other)
        super and
          @function_name == other.function_name and @function_args == other.function_args
      end
    end
  end
end
