require File.join(File.dirname(__FILE__), 'abstract_session_proxy')

module Sunspot
  module SessionProxy
    class SilentFailSessionProxy < AbstractSessionProxy
      
      attr_reader :search_session
      
      delegate :new_search, :search, :config,
                :new_more_like_this, :more_like_this,
                :delete_dirty, :delete_dirty?,
                :to => :search_session
      
      def initialize(search_session = Sunspot.session)
        @search_session = search_session
      end
      
      def rescued_exception(method, e)
        $stderr.puts("Exception in #{method}: #{e.message}")
      end

      SUPPORTED_METHODS = [
        :batch, :commit, :commit_if_dirty, :commit_if_delete_dirty, :dirty?,
        :index!, :index, :optimize, :remove!, :remove, :remove_all!, :remove_all,
        :remove_by_id!, :remove_by_id
      ]

      SUPPORTED_METHODS.each do |method|
        module_eval(<<-RUBY)
          def #{method}(*args, &block)
            begin
              search_session.#{method}(*args, &block)
            rescue => e
              self.rescued_exception(:#{method}, e)
            end
          end
        RUBY
      end
      
    end
  end
end
