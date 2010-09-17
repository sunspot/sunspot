module Sunspot
  module Rails
    module SolrLogging
      class <<self
        def included(base)
          base.module_eval { alias_method_chain(:request, :rails_logging) }
        end
      end

      def request_with_rails_logging(path, params={}, *extra)

        # Set up logging text.
        body = (params.nil? || params.empty?) ? extra.first : params.inspect
        action = path[1..-1].capitalize
        if body == "<commit/>"
          action = 'Commit'
          body = ''
        end
        body = body[0, 800] + '...' if body.length > 800

        # Make request and log.
        response = nil
        begin
          ms = Benchmark.ms do
            response = request_without_rails_logging(path, params, *extra)
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

begin
  RSolr::Client.module_eval { include(Sunspot::Rails::SolrLogging) }
rescue NameError # RSolr 0.9.6
  RSolr::Connection::Base.module_eval { include(Sunspot::Rails::SolrLogging) }
end
