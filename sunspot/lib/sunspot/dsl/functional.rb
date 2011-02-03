module Sunspot
  module DSL
    # 
    # Mixin DSL to accept functions.
    #
    module Functional

      #
      # Specify a function query with a block that returns an expression.
      #
      # === Examples
      #
      #   function { 10 }
      #   function { :average_rating }
      #   function { sum(:average_rating, 10) }
      #
      # See http://wiki.apache.org/solr/FunctionQuery for a list of all
      # applicable functions
      #
      def function(&block)
        expression = Sunspot::Util.instance_eval_or_call(
          Function.new(self),
          &block
        )
        create_function_query(expression)
      end

      #
      # Creates an AbstractFunctionQuery from an expression, also called by
      # Sunspot::DSL::Function
      #
      def create_function_query(expression) #:nodoc:
        if expression.is_a?(Sunspot::Query::FunctionQuery)
          expression
        elsif expression.is_a?(Symbol)
          Sunspot::Query::FieldFunctionQuery.new(@setup.field(expression))
        else
          Sunspot::Query::ConstantFunctionQuery.new(expression)
        end
      end
    end
  end
end

