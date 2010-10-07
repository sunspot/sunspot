require File.join(File.dirname(__FILE__), 'abstract_session_proxy')

module Sunspot
  module SessionProxy
    # 
    # This session proxy implementation allows Sunspot to be used with a
    # master/slave Solr deployment. All write methods are delegated to a master
    # session, and read methods are delegated to a slave session.
    #
    class MasterSlaveSessionProxy < AbstractSessionProxy
      #
      # The session that connects to the master Solr instance.
      #
      attr_reader :master_session
      # 
      # The session that connects to the slave Solr instance.
      #
      attr_reader :slave_session

      delegate :batch, :commit, :commit_if_delete_dirty, :commit_if_dirty,
               :config, :delete_dirty?, :dirty?, :index, :index!, :optimize, :remove,
               :remove!, :remove_all, :remove_all!, :remove_by_id,
               :remove_by_id!, :to => :master_session
      delegate :new_search, :search, :new_more_like_this, :more_like_this, :to => :slave_session

      def initialize(master_session, slave_session)
        @master_session, @slave_session = master_session, slave_session
      end

      # 
      # By default, return the configuration for the master session. If the
      # +delegate+ param is +:slave+, then return config for the slave session.
      #
      def config(delegate = :master)
        case delegate
        when :master then @master_session.config
        when :slave then  @slave_session.config
        else raise(ArgumentError, "Expected :master or :slave")
        end
      end
    end
  end
end
