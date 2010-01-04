module Sunspot
  module SessionProxy
    # 
    # A concrete implementation of ShardingSessionProxy that determines the
    # shard for a given object based on the hash of its class and ID.
    #
    # <strong>If you change the number of shard sessions that this proxy
    # encapsulates, all objects will point to a different shard.</strong> If you
    # plan on adding more shards over time, consider your own
    # ShardingSessionProxy implementation that does not determine the session
    # using modular arithmetic (e.g., IDs 1-10000 go to shard 1, 10001-20000 go
    # to shard 2, etc.)
    #
    # This implementation will, on average, yield an even distribution of
    # objects across shards.
    #
    # Unlike the abstract ShardingSessionProxy, this proxy supports the
    # #remove_by_id method.
    #
    class IdShardingSessionProxy < ShardingSessionProxy
      #
      # The shard sessions encapsulated by this class.
      #
      attr_reader :sessions
      alias_method :all_sessions, :sessions #:nodoc:

      # 
      # Initialize with a search session (see ShardingSessionProxy.new) and a
      # collection of one or more shard sessions. See note about changing the
      # number of shard sessions in the documentation for this class.
      #
      def initialize(search_session, shard_sessions)
        super(search_session)
        @sessions = shard_sessions
      end

      # 
      # Return a session based on the hash of the class and ID, modulo the
      # number of shard sessions.
      #
      def session_for(object) #:nodoc:
        session_for_index_id(Adapters::InstanceAdapter.adapt(object).index_id)
      end

      # 
      # See Sunspot.remove_by_id
      #
      def remove_by_id(clazz, id)
        session_for_index_id(
          Adapters::InstanceAdapter.index_id_for(clazz, id)
        ).remove_by_id(clazz, id)
      end

      # 
      # See Sunspot.remove_by_id!
      #
      def remove_by_id!(clazz, id)
        session_for_index_id(
          Adapters::InstanceAdapter.index_id_for(clazz, id)
        ).remove_by_id!(clazz, id)
      end

      private

      def session_for_index_id(index_id)
        @sessions[id_hash(index_id) % @sessions.length]
      end

      # 
      # This method is implemented explicitly instead of using String#hash to
      # give predictable behavior across different Ruby interpreters.
      #
      if "".respond_to?(:bytes) # Ruby 1.9
        def id_hash(id)
          id.bytes.inject { |hash, byte| hash * 31 + byte }
        end
      else
        def id_hash(id)
          hash, i, len = 0, 0, id.length
          while i < len
            hash = hash * 31 + id[i]
            i += 1
          end
          hash
        end
      end
    end
  end
end
