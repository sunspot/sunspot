module Sunspot
  module SessionProxy
    class IdShardingSessionProxy < ShardingSessionProxy
      attr_reader :sessions
      alias_method :all_sessions, :sessions

      def initialize(search_session, shard_sessions)
        super(search_session)
        @sessions = shard_sessions
      end

      def session_for(object)
        session_for_index_id(Adapters::InstanceAdapter.adapt(object).index_id)
      end

      def remove_by_id(clazz, id)
        session_for_index_id(
          Adapters::InstanceAdapter.index_id_for(clazz, id)
        ).remove_by_id(clazz, id)
      end

      def remove_by_id!(clazz, id)
        session_for_index_id(
          Adapters::InstanceAdapter.index_id_for(clazz, id)
        ).remove_by_id!(clazz, id)
      end

      private

      def session_for_index_id(index_id)
        @sessions[index_id.hash % @sessions.length]
      end
    end
  end
end
