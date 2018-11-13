# frozen_string_literal: true

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
    # * atomic_update with arguments
    # * atomic_update! with arguments
    #
    class TbcSessionProxy < AbstractSessionProxy
      not_supported :batch, :config, :remove_by_id, :remove_by_id!, :atomic_update, :atomic_update!, :remove_all, :remove_all!
      attr_reader :admin_session, :config

      #
      # +search_session+ is the session that should be used for searching.
      #
      def initialize(date_from: (Time.now.utc - 1.month).to_i, date_to: Time.now.utc.to_i, collections: [])
        @config = Sunspot::Rails.configuration
        @admin_session = AdminSessionProxy.new
        @date_from = Time.at(date_from)
        @date_to = Time.at(date_to)
        @collections = collections
      end

      # def with_exception_handling
      #   retry_count = 0
      #   max_retry_count = 5
      #   retry_interval = 0.5
      #   begin
      #     yield
      #   rescue RSolr::Error::ConnectionRefused, RSolr::Error::Http => e
      #     ::Rails.logger.info "Error connecting to Solr #{@config.inspect}"

      #     if retry_count < max_retry_count
      #       retry_count += 1
      #       ::Rails.logger.info "Retrying Solr connection... (#{retry_count} of #{max_retry_count})"
      #       sleep retry_interval
      #       @my_session = FailoverSession.new.new_session(retry_count)
      #       retry
      #     else
      #       ::Rails.logger.error 'Reached max Solr connection retry count.'
      #       raise e
      #     end
      #   end
      # rescue StandardError => e
      #   ::Rails.logger.error "Exception: #{e.inspect}"
      #   raise e
      # end

      #
      # Return the appropriate collection session for the object.
      def session_for(object)
        obj_col_name = collection(object)
        # Check if the collection is present, if not we create it
        admin_session.create_collection(collection_name: obj_col_name) if !admin_session.collections.include?(obj_col_name)

        c = Sunspot::Configuration.build
        c.solr.url = URI::HTTP.build(
          host: @config.hostnames[rand(@config.hostnames.size)],
          port: @config.port,
          path: "/solr/#{obj_col_name}"
        ).to_s
        c.solr.read_timeout = @config.read_timeout
        c.solr.open_timeout = @config.open_timeout
        c.solr.proxy = @config.proxy
        Session.new(c)
      end

      #
      # Return all collections sessions.
      #
      def all_sessions
        @sessions = []
        admin_session.collections.each do |col|
          c = Sunspot::Configuration.build
          c.solr.url = URI::HTTP.build(
            host: @config.hostnames[rand(@config.hostnames.size)],
            port: @config.port,
            path: "/solr/#{col}"
          ).to_s
          c.solr.read_timeout = conf.read_timeout
          c.solr.open_timeout = conf.open_timeout
          c.solr.proxy = conf.proxy
          @sessions << ession.new(c)
        end
      end

      #
      # See Sunspot.index
      #
      def index(*objects)
        using_collection_session(objects) { |session, group| session.index(group) }
      end

      #
      # See Sunspot.index!
      #
      def index!(*objects)
        using_collection_session(objects) { |session, group| session.index!(group) }
      end

      #
      # See Sunspot.remove
      #
      def remove(*objects)
        using_collection_session(objects) { |session, group| session.remove(group) }
      end

      #
      # See Sunspot.remove!
      #
      def remove!(*objects)
        using_collection_session(objects) { |session, group| session.remove!(group) }
      end

      #
      # Commit all shards. See Sunspot.commit
      #
      def commit
        all_sessions.each(&:commit)
      end

      #
      # Optimize all shards. See Sunspot.optimize
      #
      def optimize
        all_sessions.each(&:optimize)
      end

      #
      # Commit all dirty sessions. Only dirty sessions will be committed.
      #
      # See Sunspot.commit_if_dirty
      #
      def commit_if_dirty
        all_sessions.each(&:commit_if_dirty)
      end

      #
      # Commit all delete-dirty sessions. Only delete-dirty sessions will be
      # committed.
      #
      # See Sunspot.commit_if_delete_dirty
      #
      def commit_if_delete_dirty
        all_sessions.each(&:commit_if_delete_dirty)
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
        search = @search_session.new_search(*types)
        search.build do
          adjust_solr_params { |params| params[:collections] = collections.join(',') }
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
      def search(*types)
        new_search(*types).execute
      end

      def more_like_this(object, &block)
        # FIXME: should use shards
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
        all_sessions.any?(&:dirty?)
      end

      #
      # True if any shard session is delete-dirty. Note that directly using the
      # #commit_if_delete_dirty method is more efficient if that's what you're
      # trying to do, since in that case only the delete-dirty sessions are
      # committed.
      #
      def delete_dirty?
        all_sessions.any?(&:delete_dirty?)
      end

      private

      def collection(object)
        if !object.respond_to?(:time_routed_on)
          raise NoMethodError, "Method :time_routed_on on class #{object.class} is not defined"
        else
          time_routed_on = object.published_at.utc
          collection_name = "#{@config.collection['base_name']}_#{time_routed_on.year}_#{time_routed_on.month}"
          collection_name
        end
      end

      #
      # Group the objects by which collection session they correspond to, and yield
      # each session and is corresponding group of objects.
      #
      def using_collection_session(objects)
        grouped_objects = Hash.new { |h, k| h[k] = [] }
        objects.flatten.each { |object| grouped_objects[session_for(object)] << object }
        grouped_objects.each_pair do |session, group|
          yield(session, group)
        end
      end
    end
  end
end
