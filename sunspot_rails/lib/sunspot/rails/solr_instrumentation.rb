module Sunspot
  module Rails
    module SolrInstrumentation
      extend ActiveSupport::Concern

      included do
        alias_method_chain :execute, :as_instrumentation
      end


      def execute_with_as_instrumentation(path, params={}, *extra)
        ActiveSupport::Notifications.instrument("request.rsolr",
                                                {:path => path, :parameters => params}) do
          execute_without_as_instrumentation(path, params, *extra)
        end
      end
    end
  end
end
