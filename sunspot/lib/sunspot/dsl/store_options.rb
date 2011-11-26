module Sunspot
  module DSL #:nodoc:
    module StoreOptions
      def store_options(options)
        @query.store_options = options
      end
    end
  end
end
