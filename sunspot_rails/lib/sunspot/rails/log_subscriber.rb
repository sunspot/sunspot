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

        # produces: path=select parameters={fq: ["type:Tag"], q: "rossi", fl: "* score", qf: "tag_name_text", defType: "edismax", start: 0, rows: 20}
        path = color(event.payload[:path], nil, bold: true)
        parameters = event.payload[:parameters].map { |k, v|
          v = "\"#{v}\"" if v.is_a? String
          v = v.to_s.gsub(/\\/,'') # unescape
          "#{k}: #{color(v, nil, bold: true)}"
        }.join(', ')
        request = "path=#{path} parameters={#{parameters}}"

        debug "  #{color(name, GREEN, bold: true)}  [ #{request} ]"
      end
    end
  end
end

Sunspot::Rails::LogSubscriber.attach_to :rsolr
