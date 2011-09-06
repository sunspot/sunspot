module Sunspot
  module Rails
    module SolrLogging

      class <<self
        def included(base)
          base.alias_method_chain :execute, :rails_logging
        end
      end

      COMMIT = %r{<commit/>}

      def execute_with_rails_logging(client, request_context)
        body = (request_context[:data]||"").dup
        action = request_context[:path].capitalize
        if body =~ COMMIT
          action = "Commit"
          body = ""
        end
        body = body[0, 800] + '...' if body.length > 800

        # Make request and log.
        response = nil
        begin
          ms = Benchmark.ms do
            response = execute_without_rails_logging(client, request_context)
          end
          log_name = 'Solr %s (%.1fms)' % [action, ms]
          ::Rails.logger.debug(format_log_entry(log_name, body))
        rescue Exception => e
          log_name = 'Solr %s (Error)' % [action]
          ::Rails.logger.error(format_log_entry(log_name, body))
          raise e
        end

        response
      end

      private

      def format_log_entry(message, dump = nil)
        @colorize_logging ||= begin
          ::Rails.application.config.colorize_logging # Rails 3
        rescue NoMethodError
          ActiveRecord::Base.colorize_logging # Rails 2
        end
        if @colorize_logging
          message_color, dump_color = "4;32;1", "0;1"
          log_entry = "  \e[#{message_color}m#{message}\e[0m   "
          log_entry << "\e[#{dump_color}m%#{String === dump ? 's' : 'p'}\e[0m" % dump if dump
          log_entry
        else
          "%s  %s" % [message, dump]
        end
      end
    end
  end
end

RSolr::Connection.module_eval do
  include Sunspot::Rails::SolrLogging
end
