require 'monitor'
require File.join(File.dirname(__FILE__), 'abstract_session_proxy')

module Sunspot
  module SessionProxy
    # 
    # This class implements a session proxy that creates a different Session
    # object for each thread. Any multithreaded application should use this
    # proxy.
    #
    class ThreadLocalSessionProxy < AbstractSessionProxy
      FINALIZER = Proc.new do |object_id|
        Thread.current[:"sunspot_session_#{object_id}"] = nil
      end

      # The configuration with which the thread-local sessions are initialized.
      attr_reader :config
      @@next_id = 0

      delegate :batch, :commit, :commit_if_delete_dirty, :commit_if_dirty, :delete_dirty?, :dirty?, :index, :index!, :new_search, :optimize, :remove, :remove!, :remove_all, :remove_all!, :remove_by_id, :remove_by_id!, :search, :more_like_this, :new_more_like_this, :to => :session

      # 
      # Optionally pass an existing Sunspot::Configuration object. If none is
      # passed, a default configuration is used; it can then be modified using
      # the #config attribute.
      #
      def initialize(config = Sunspot::Configuration.new)
        @config = config
        ObjectSpace.define_finalizer(self, FINALIZER)
      end

      def session #:nodoc:
        Thread.current[:"sunspot_session_#{object_id}"] ||= Session.new(config)
      end
    end
  end
end
