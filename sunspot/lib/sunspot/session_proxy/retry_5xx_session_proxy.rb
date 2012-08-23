require File.join(File.dirname(__FILE__), 'abstract_session_proxy')

module Sunspot
  module SessionProxy
    class Retry5xxSessionProxy < AbstractSessionProxy

      class RetryHandler
        attr_reader :search_session

        def initialize(search_session)
          @search_session = search_session
        end

        def method_missing(m, *args, &block)
          retry_count = 1
          begin
            search_session.send(m, *args, &block)
          rescue Errno::ECONNRESET => e
            if retry_count > 0
              $stderr.puts "Error - #{e.message[/^.*$/]} - retrying..."
              retry_count -= 1
              retry
            else
              $stderr.puts "Error - #{e.message[/^.*$/]} - ignoring..."
            end
          rescue RSolr::Error::Http => e
            if (500..599).include?(e.response[:status].to_i)
              if retry_count > 0
                $stderr.puts "Error - #{e.message[/^.*$/]} - retrying..."
                retry_count -= 1
                retry
              else
                $stderr.puts "Error - #{e.message[/^.*$/]} - ignoring..."
                e.response
              end
            else
              raise e
            end
          end
        end
      end

      attr_reader :search_session
      attr_reader :retry_handler

      delegate :new_search, :search, :config,
                :new_more_like_this, :more_like_this,
                :delete_dirty, :delete_dirty?,
                :to => :search_session

      def initialize(search_session = Sunspot.session)
        @search_session = search_session
        @retry_handler = RetryHandler.new(search_session)
      end

      def rescued_exception(method, e)
        $stderr.puts("Exception in #{method}: #{e.message}")
      end

      delegate :batch, :commit, :commit_if_dirty, :commit_if_delete_dirty,
        :dirty?, :index!, :index, :optimize, :remove!, :remove, :remove_all!,
        :remove_all, :remove_by_id!, :remove_by_id,
        :to => :retry_handler

    end
  end
end
