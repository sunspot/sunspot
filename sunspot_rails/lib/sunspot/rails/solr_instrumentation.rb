module Sunspot
  module Rails
    module SolrInstrumentation
      extend ActiveSupport::Concern

      included do
        prepend Sunspot::SolrRailsInstrumentation
      end
    end
  end

  module SolrRailsInstrumentation
    def send_and_receive(path, opts)
      parameters = (opts[:params] || {})
      parameters.merge!(opts[:data]) if opts[:data].is_a? Hash
      payload = {path: path, parameters: parameters}
      ActiveSupport::Notifications.instrument("request.rsolr", payload) do
        super(path,opts)
      end
    end
  end
end