require 'sunspot'
require File.join(File.dirname(__FILE__), 'rails', 'configuration')
require File.join(File.dirname(__FILE__), 'rails', 'adapters')
require File.join(File.dirname(__FILE__), 'rails', 'request_lifecycle')
require File.join(File.dirname(__FILE__), 'rails', 'searchable')

module Sunspot #:nodoc:
  module Rails #:nodoc:
    autoload :StubSessionProxy, File.join(File.dirname(__FILE__), 'rails', 'stub_session_proxy')
    autoload :Server, File.join(File.dirname(__FILE__), 'rails', 'server')
    autoload :VERSION, File.join(File.dirname(__FILE__), 'rails', 'version')

    class <<self
      attr_writer :configuration

      def configuration
        @configuration ||= Sunspot::Rails::Configuration.new
      end

      def reset
        @configuration = nil
      end

      def build_session(configuration = self.configuration)
        if configuration.has_master?
          SessionProxy::MasterSlaveSessionProxy.new(
            SessionProxy::ThreadLocalSessionProxy.new(master_config(configuration)),
            SessionProxy::ThreadLocalSessionProxy.new(slave_config(configuration))
          )
        else
          SessionProxy::ThreadLocalSessionProxy.new(slave_config(configuration))
        end
      end

      private

      def master_config(sunspot_rails_configuration)
        config = Sunspot::Configuration.build
        config.solr.url = URI::HTTP.build(
          :host => sunspot_rails_configuration.master_hostname,
          :port => sunspot_rails_configuration.master_port,
          :path => sunspot_rails_configuration.master_path
        ).to_s
        config
      end

      def slave_config(sunspot_rails_configuration)
        config = Sunspot::Configuration.build
        config.solr.url = URI::HTTP.build(
          :host => configuration.hostname,
          :port => configuration.port,
          :path => configuration.path
        ).to_s
        config
      end
    end
  end
end
