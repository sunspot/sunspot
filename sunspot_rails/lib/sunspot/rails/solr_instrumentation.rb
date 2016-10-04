module Sunspot
  module Rails
    module SolrInstrumentation
      extend ActiveSupport::Concern

      included do
        if Module.respond_to?(:prepend)
          prepend Sunspot::SolrRailsInstrumentation
        else
          include Sunspot::SolrRailsInstrumentation
          alias_method :send_and_receive_without_as_instrumentation, :send_and_receive
        end
      end

    end
  end
end

module Sunspot
  module SolrRailsInstrumentation
    def send_and_receive(path, opts)
      parameters = (opts[:params] || {})
      parameters.merge!(opts[:data]) if opts[:data].is_a? Hash
      payload = {:path => path, :parameters => parameters}
      ActiveSupport::Notifications.instrument("request.rsolr", payload) do
        Module.respond_to?(:prepend) ?  super(path,opts) : send_and_receive_without_as_instrumentation(path, opts)
      end
    end
  end
end