module Sunspot
  module Rails
    class LogSubscriber < ActiveSupport::LogSubscriber
      def self.runtime=(value)
        Thread.current["sorl_runtime"] = value
      end

      def self.runtime
        Thread.current["sorl_runtime"] ||= 0
      end

      def self.reset_runtime
        rt, self.runtime = runtime, 0
        rt
      end
      
      def self.logger=(logger)
        @logger = logger
      end
      
      def self.logger
        @logger if defined?(@logger)
      end
      
      def logger
        self.class.logger || ::Rails.logger
      end

      def request(event)
        self.class.runtime += event.duration
        return unless logger.debug?

        name = '%s (%.1fms)' % ["SOLR Request", event.duration]

        # produces: path=/select parameters={fq: ["type:Tag"], q: rossi, fl: * score, qf: tag_name_text, defType: dismax, start: 0, rows: 20}
        parameters = event.payload[:parameters].map { |k, v| "#{k}: #{color(v, BOLD, true)}" }.join(', ')
        request = "path=#{event.payload[:path]} parameters={#{parameters}}"

        debug "  #{color(name, GREEN, true)}  [ #{request} ]"
      end
    end
  end
end

Sunspot::Rails::LogSubscriber.attach_to :rsolr
