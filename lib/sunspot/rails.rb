require 'sunspot'
require 'sunspot/rails/configuration'
require 'sunspot/rails/adapters'
require 'sunspot/rails/request_lifecycle'
require 'sunspot/rails/searchable'

module Sunspot #:nodoc:
  module Rails #:nodoc:
    class <<self
      attr_writer :configuration

      def configuration
        @configuration ||= Sunspot::Rails::Configuration.new
      end

      def session
        Thread.current[:sunspot_rails_session] ||=
          begin
            session = Sunspot::Session.new
            session.config.solr.url = URI::HTTP.build(
              :host => configuration.hostname,
              :port => configuration.port,
              :path => configuration.path
            ).to_s
            session
          end
      end
    end
  end
end
