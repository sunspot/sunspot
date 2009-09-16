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
    end
  end
end
