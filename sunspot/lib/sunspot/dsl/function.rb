module Sunspot
  module DSL
    class Function #:nodoc:
      def initialize(functional) #:nodoc:
        @functional = functional
      end

      def method_missing(method, *args, &block)
        function_args = args.map { |arg| @functional.create_function_query(arg) }
        Sunspot::Query::FunctionalFunctionQuery.new(method, function_args)
      end
    end
  end
end
