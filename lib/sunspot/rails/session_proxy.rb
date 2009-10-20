module Sunspot
  module Rails
    class SessionProxy
      extend MonitorMixin

      class <<self
        def instance
          synchronize do
            @instance ||= new
          end
        end

        def reset!
          synchronize do
            @instance = nil
          end
        end

        private :new
      end

      delegate :new_search, :search, :to => :read_session
      delegate :index, :index!, :commit, :remove, :remove!, :remove_by_id,
               :remove_by_id!, :remove_all, :remove_all!, :dirty?, :commit_if_dirty, :batch,
               :to => :write_session

      def initialize
        @configuration = Sunspot::Rails::Configuration.new
      end

      private

      def read_session
        Thread.current[:sunspot_rails_read_session] ||=
          begin
            session = Sunspot::Session.new
            session.config.solr.url = URI::HTTP.build(
              :host => @configuration.hostname,
              :port => @configuration.port,
              :path => @configuration.path
            ).to_s
            session
          end
      end

      def write_session
        Thread.current[:sunspot_rails_write_session] ||=
          if @configuration.has_master?
            master_session = Sunspot::Session.new
            master_session.config.solr.url = URI::HTTP.build(
              :host => configuration.master_hostname,
              :port => configuration.master_port,
              :path => configuration.master_path
            ).to_s
            master_session
          else
            read_session
          end
      end
    end
  end
end
