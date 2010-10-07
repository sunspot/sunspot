require File.join(File.dirname(__FILE__), 'abstract_session_proxy')

module Sunspot
  module SessionProxy
    # 
    # This is a generic abstract implementation of a session proxy that allows
    # Sunspot to be used with a distributed (sharded) Solr deployment. Concrete
    # subclasses should implement the #session_for method, which takes a
    # searchable object and returns a Session that points to the appropriate
    # Solr shard for that object. Subclasses should also implement the
    # #all_sessions object, which returns the collection of all sharded Session
    # objects.
    #
    # The class is initialized with a session that points to the Solr instance
    # used to perform searches. Searches will have the +:shards+ param injected,
    # containing references to the Solr instances returned by #all_sessions.
    #
    # For more on distributed search, see:
    # http://wiki.apache.org/solr/DistributedSearch
    #
    # The following methods are not supported (although subclasses may in some
    # cases be able to support them):
    #
    # * batch
    # * config
    # * remove_by_id
    # * remove_by_id!
    # * remove_all with an argument
    # * remove_all! with an argument
    #
    class ShardingSessionProxy < AbstractSessionProxy
      not_supported :batch, :config, :remove_by_id, :remove_by_id!

      # 
      # +search_session+ is the session that should be used for searching.
      #
      def initialize(search_session = Sunspot.session.new)
        @search_session = search_session
      end

      # 
      # Return the appropriate shard session for the object.
      #
      # <strong>Concrete subclasses must implement this method.</strong>
      #
      def session_for(object)
        raise NotImplementedError
      end

      # 
      # Return all shard sessions.
      #
      # <strong>Concrete subclasses must implement this method.</strong>
      #
      def all_sessions
        raise NotImplementedError
      end

      # 
      # See Sunspot.index
      #
      def index(*objects)
        using_sharded_session(objects) { |session, group| session.index(group) }
      end

      # 
      # See Sunspot.index!
      #
      def index!(*objects)
        using_sharded_session(objects) { |session, group| session.index!(group) }
      end

      # 
      # See Sunspot.remove
      #
      def remove(*objects)
        using_sharded_session(objects) { |session, group| session.remove(group) }
      end

      # 
      # See Sunspot.remove!
      #
      def remove!(*objects)
        using_sharded_session(objects) { |session, group| session.remove!(group) }
      end

      # 
      # If no argument is passed, behaves like Sunspot.remove_all
      #
      # If an argument is passed, will raise NotSupportedError, as the proxy
      # does not know which session(s) to which to delegate this operation.
      #
      def remove_all(clazz = nil)
        if clazz
          raise NotSupportedError, "Sharding session proxy does not support remove_all with an argument."
        else
          all_sessions.each { |session| session.remove_all }
        end
      end

      # 
      # If no argument is passed, behaves like Sunspot.remove_all!
      #
      # If an argument is passed, will raise NotSupportedError, as the proxy
      # does not know which session(s) to which to delegate this operation.
      #
      def remove_all!(clazz = nil)
        if clazz
          raise NotSupportedError, "Sharding session proxy does not support remove_all! with an argument."
        else
          all_sessions.each { |session| session.remove_all! }
        end
      end

      # 
      # Commit all shards. See Sunspot.commit
      #
      def commit
        all_sessions.each { |session| session.commit }
      end

      # 
      # Optimize all shards. See Sunspot.optimize
      #
      def optimize
        all_sessions.each { |session| session.optimize }
      end

      # 
      # Commit all dirty sessions. Only dirty sessions will be committed.
      #
      # See Sunspot.commit_if_dirty
      #
      def commit_if_dirty
        all_sessions.each { |session| session.commit_if_dirty }
      end

      # 
      # Commit all delete-dirty sessions. Only delete-dirty sessions will be
      # committed.
      # 
      # See Sunspot.commit_if_delete_dirty
      #
      def commit_if_delete_dirty
        all_sessions.each { |session| session.commit_if_delete_dirty }
      end

      # 
      # Instantiate a new Search object, but don't execute it. The search will
      # have an extra :shards param injected into the query, which will tell the
      # Solr instance referenced by the search session to search across all
      # shards.
      #
      # See Sunspot.new_search
      #
      def new_search(*types)
        shard_urls = all_sessions.map { |session| session.config.solr.url }
        search = @search_session.new_search(*types)
        search.build do
          adjust_solr_params { |params| params[:shards] = shard_urls.join(',') }
          # I feel a little dirty doing this.
        end
        search
      end

      # 
      # Build and execute a new Search. The search will have an extra :shards
      # param injected into the query, which will tell the Solr instance
      # referenced by the search session to search across all shards.
      #
      # See Sunspot.search
      #
      def search(*types, &block)
        new_search(*types).execute
      end

      def more_like_this(object, &block)
        #FIXME should use shards
        new_more_like_this(object, &block).execute
      end

      def new_more_like_this(object, &block)
        @search_session.new_more_like_this(object, &block)
      end

      # 
      # True if any shard session is dirty. Note that directly using the
      # #commit_if_dirty method is more efficient if that's what you're
      # trying to do, since in that case only the dirty sessions are committed.
      #
      # See Sunspot.dirty?
      #
      def dirty?
        all_sessions.any? { |session| session.dirty? }
      end

      # 
      # True if any shard session is delete-dirty. Note that directly using the
      # #commit_if_delete_dirty method is more efficient if that's what you're
      # trying to do, since in that case only the delete-dirty sessions are
      # committed.
      #
      def delete_dirty?
        all_sessions.any? { |session| session.delete_dirty? }
      end

      private

      # 
      # Group the objects by which shard session they correspond to, and yield
      # each session and is corresponding group of objects.
      #
      def using_sharded_session(objects)
        grouped_objects = Hash.new { |h, k| h[k] = [] }
        objects.flatten.each { |object| grouped_objects[session_for(object)] << object }
        grouped_objects.each_pair do |session, group|
          yield(session, group)
        end
      end
    end
  end
end
