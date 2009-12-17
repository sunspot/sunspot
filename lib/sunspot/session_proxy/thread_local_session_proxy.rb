require File.join(File.dirname(__FILE__), 'abstract_session_proxy')

module Sunspot
  module SessionProxy
    class ThreadLocalSessionProxy < AbstractSessionProxy
      attr_reader :config

      delegate :batch, :commit, :commit_if_delete_dirty, :commit_if_dirty, :delete_dirty?, :dirty?, :index, :index!, :new_search, :remove, :remove!, :remove_all, :remove_all!, :remove_by_id, :remove_by_id!, :search, :to => :session

      def initialize(config)
        @config = config
      end

      def session #:nodoc:
        Thread.current[:sunspot_session] ||= Session.new(:config)
      end
    end
  end
end
