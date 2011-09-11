module Sunspot
  module DSL
    # 
    # This top-level DSL class is the context in which the block passed to
    # Sunspot.query. See Sunspot::DSL::StandardQuery, Sunspot::DSL::FieldQuery,
    # and Sunspot::DSL::Scope for the full API presented.
    #
    class Search < StandardQuery
      def initialize(search, setup) #:nodoc:
        @search = search
        super(search, search.query, setup)
      end

      # 
      # Retrieve the data accessor used to load instances of the given class
      # out of persistent storage. Data accessors are free to implement any
      # extra methods that may be useful in this context.
      #
      # ==== Example
      #
      #   Sunspot.search Post do
      #     data_acccessor_for(Post).includes = [:blog, :comments]
      #   end
      #
      def data_accessor_for(clazz)
        @search.data_accessor_for(clazz)
      end
    end
  end
end
