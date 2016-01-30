require 'sunspot'
require File.join(File.dirname(__FILE__), 'rails', 'configuration')
require File.join(File.dirname(__FILE__), 'rails', 'adapters')
require File.join(File.dirname(__FILE__), 'rails', 'request_lifecycle')
require File.join(File.dirname(__FILE__), 'rails', 'searchable')

module Sunspot #:nodoc:
  module Rails #:nodoc:
    autoload :SolrInstrumentation, File.join(File.dirname(__FILE__), 'rails', 'solr_instrumentation')
    autoload :StubSessionProxy, File.join(File.dirname(__FILE__), 'rails', 'stub_session_proxy')
    begin
      require 'sunspot_solr'
      autoload :Server, File.join(File.dirname(__FILE__), 'rails', 'server')
    rescue LoadError
      # We're fine
    end

    class <<self
      attr_writer :configuration

      def configuration
        @configuration ||= Sunspot::Rails::Configuration.new
      end

      def reset
        @configuration = nil
      end

      def build_session(configuration = self.configuration)
        if configuration.disabled?
          StubSessionProxy.new(Sunspot.session)
        elsif configuration.has_master?
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
        config.solr.url = URI.parse("#{sunspot_rails_configuration.scheme}://example.com").tap do |builder|
          builder.hostname = sunspot_rails_configuration.master_hostname
          builder.port = sunspot_rails_configuration.master_port
          builder.path = sunspot_rails_configuration.master_path
          builder.userinfo = sunspot_rails_configuration.userinfo
        end.to_s
        config.solr.read_timeout = sunspot_rails_configuration.read_timeout
        config.solr.open_timeout = sunspot_rails_configuration.open_timeout
        config.solr.proxy = sunspot_rails_configuration.proxy
        config.solr.update_format = sunspot_rails_configuration.update_format
        config
      end

      def slave_config(sunspot_rails_configuration)
        config = Sunspot::Configuration.build
        config.solr.url = URI.parse("#{sunspot_rails_configuration.scheme}://example.com").tap do |builder|
          builder.hostname = sunspot_rails_configuration.hostname
          builder.port = sunspot_rails_configuration.port
          builder.path = sunspot_rails_configuration.path
          builder.userinfo = sunspot_rails_configuration.userinfo
        end.to_s
        config.solr.read_timeout = sunspot_rails_configuration.read_timeout
        config.solr.open_timeout = sunspot_rails_configuration.open_timeout
        config.solr.proxy = sunspot_rails_configuration.proxy
        config.solr.update_format = sunspot_rails_configuration.update_format
        config
      end
    end
  end
end
