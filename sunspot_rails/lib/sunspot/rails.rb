require 'sunspot'
require 'sunspot/rails/configuration'
require 'sunspot/rails/adapters'
require 'sunspot/rails/request_lifecycle'
require 'sunspot/rails/searchable'
require 'sunspot/rails/util'

module Sunspot #:nodoc:
  module Rails #:nodoc:
    class <<self
      attr_writer :configuration

      def configuration
        @configuration ||= Sunspot::Rails::Configuration.new
      end

      def reset
        @master_session = @configuration = nil
      end
    end
  end
end
