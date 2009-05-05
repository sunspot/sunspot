require 'sunspot'

module Sunspot #:nodoc:
  module Rails #:nodoc:
    class <<self
      def configuration
        @configuration ||= Sunspot::Rails::Configuration.new
      end
    end
  end
end
