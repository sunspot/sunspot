module Sunspot
  module Rails
    class <<self
      def configuration
        @configuration ||= Sunspot::Rails::Configuration.new
      end
    end
  end
end
