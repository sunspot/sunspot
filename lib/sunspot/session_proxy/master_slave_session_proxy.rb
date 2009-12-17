require File.join(File.dirname(__FILE__), 'abstract_session_proxy')

module Sunspot
  module SessionProxy
    class MasterSlaveSessionProxy < AbstractSessionProxy
      attr_reader :master_session, :slave_session

      delegate :batch, :commit, :commit_if_delete_dirty, :commit_if_dirty,
               :config, :delete_dirty?, :dirty?, :index, :index!, :remove,
               :remove!, :remove_all, :remove_all!, :remove_by_id,
               :remove_by_id!, :to => :master_session
      delegate :new_search, :search, :to => :slave_session

      def initialize(master_session, slave_session)
        @master_session, @slave_session = master_session, slave_session
      end

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
