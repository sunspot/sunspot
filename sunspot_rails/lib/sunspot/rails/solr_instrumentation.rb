module Sunspot
  module Rails
    module SolrInstrumentation
      extend ActiveSupport::Concern

      included do
        alias_method :request_without_as_instrumentation, :request
        alias_method :request, :request_with_as_instrumentation
      end

      module InstanceMethods
        def request_with_as_instrumentation(path, params={}, *extra)
          ActiveSupport::Notifications.instrument("request.rsolr",
                                                  {:path => path, :parameters => params}) do
            request_without_as_instrumentation(path, params, *extra)
          end
        end
      end
    end
  end
end