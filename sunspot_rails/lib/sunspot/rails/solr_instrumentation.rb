module Sunspot
  module Rails
    module SolrInstrumentation
      extend ActiveSupport::Concern

      included do
        alias_method_chain :send_and_receive, :as_instrumentation
      end


      def send_and_receive_with_as_instrumentation(path, opts)
        parameters = (opts[:params] || {})
        parameters.merge!(opts[:data]) if opts[:data].is_a? Hash
        payload = {:path => path, :parameters => parameters}
        ActiveSupport::Notifications.instrument("request.rsolr", payload) do
          send_and_receive_without_as_instrumentation(path, opts)
        end
      end
    end
  end
end
