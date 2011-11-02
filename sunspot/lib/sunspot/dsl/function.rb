module Sunspot
  module DSL
    class Function #:nodoc:
      def initialize(functional) #:nodoc:
        @functional = functional
      end

      # Special case to handle <http://wiki.apache.org/solr/FunctionQuery#sub>
      # because `Kernel#sub` exists so `method_missing` will not be called
      # for this function.
      def sub(*args) #:nodoc:
        create_function_query(:sub, *args)
      end

      def method_missing(method, *args, &block)
        create_function_query(method, *args)
      end

      private

      def create_function_query(method, *args)
        function_args = args.map { |arg| @functional.create_function_query(arg) }
        Sunspot::Query::FunctionalFunctionQuery.new(method, function_args)
      end
    end
  end
end
