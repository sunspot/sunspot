# frozen_string_literal: true

module Sunspot
  module SessionProxy
    #
    # Time Routed Aliases solr 7 drawbacks:
    # only time based use cases are supported, time filters in queries are not considered
    # to filter the collections during search and old collections are not optimized.
    # Most of these improvements are already in progress.
    # Anyways TbcSessionProxy is meant to address previous issues and to cover Time Routed Aliases on
    # previous solr versions
    #
    # TbcSessionProxy automatically creates new collections as it routes documents to the
    # correct collection based on its timestamp.
    # This approach allows for indefinite indexing of data without degradation of
    # performance otherwise experienced due to the continuous growth of a single index.
    #
    # For more info, see:
    # https://lucene.apache.org/solr/guide/7_4\5/time-routed-aliases.html
    #
    # The following methods are not supported (although subclasses may in some
    # cases be able to support them):
    #
    # * batch
    # * remove_by_id
    # * remove_by_id!
    # * remove_all with an argument
    # * remove_all! with an argument
    # * atomic_update with arguments
    # * atomic_update! with arguments
    #
    class TbcSessionProxy < AbstractSessionProxy
      not_supported :batch, :remove_by_id, :remove_by_id!, :atomic_update,
                    :atomic_update!, :remove_all, :remove_all!

      attr_reader :solr, :config, :search_collections

      def initialize(
        config: Sunspot::Configuration.build,
        date_from: default_init_date,
        date_to: default_end_date,
        collections: nil
      )
        @config = config
        @next_host_index = 0
        @solr = AdminSession.new(config)
        @search_collections =
          collections || calculate_search_collections(
            date_from: date_from,
            date_to: date_to
          )
      end

      #
      # Return a session.
      #
      def session
        now = Time.now.utc
        col_name = collection_name(year: now.year, month: now.month)
        solr.create_collection(collection_name: col_name) unless solr.collections.include?(col_name)
        c = Sunspot::Configuration.build
        c.solr.url = URI::HTTP.build(
          host: @config.hostnames[rand(@config.hostnames.size)],
          port: @config.port,
          path: "/solr/#{col_name}"
        ).to_s
        c.solr.read_timeout = @config.read_timeout
        c.solr.open_timeout = @config.open_timeout
        c.solr.proxy = @config.proxy
        Session.new(c)
      end

      #
      # Return the appropriate collection session for the object.
      #
      def session_for(object)
        obj_col_name = collection_for(object)
        # If collection is not present, create it!
        solr.create_collection(collection_name: obj_col_name) unless solr.collections.include?(obj_col_name)

        c = Sunspot::Configuration.build
        c.solr.url = URI::HTTP.build(
          host: get_hostname,
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
        solr.collections(force: true).each do |col|
          c = Sunspot::Configuration.build
          c.solr.url = URI::HTTP.build(
            host: get_hostname,
            port: @config.port,
            path: "/solr/#{col}"
          ).to_s
          c.solr.read_timeout = @config.read_timeout
          c.solr.open_timeout = @config.open_timeout
          c.solr.proxy = @config.proxy
          @sessions << Session.new(c)
        end
        @sessions
      end

      #
      # See Sunspot.index
      #
      def index(*objects)
        using_collection_session(objects) do |session, group|
          with_exception_handling { session.index(group) }
        end
      end

      #
      # See Sunspot.index!
      #
      def index!(*objects)
        using_collection_session(objects) do |session, group|
          with_exception_handling { session.index!(group) }
        end
      end

      #
      # See Sunspot.remove
      #
      def remove(*objects)
        using_collection_session(objects) do |session, group|
          with_exception_handling { session.remove(group) }
        end
      end

      #
      # See Sunspot.remove!
      #
      def remove!(*objects)
        using_collection_session(objects) do |session, group|
          with_exception_handling { session.remove!(group) }
        end
      end

      #
      # Commit all shards. See Sunspot.commit
      #
      def commit(soft_commit = false)
        all_sessions.each{ |s| s.commit(soft_commit) }
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
      # See Sunspot.remove_all
      #
      def remove_all(*classes)
        all_sessions.each{ |s| s.remove_all(classes) }
      end

      #
      # See Sunspot.remove_all!
      #
      def remove_all!(*classes)
        remove_all(classes)
        commit
      end

      #
      # Instantiate a new Search object, but don't execute it. The search will
      # have an extra :collections param injected into the query, which will tell the
      # Solr instance referenced by the search session to search across all
      # shards.
      #
      # See Sunspot.new_search
      #
      # If search_collections is empty we search on the latest collection
      def new_search(*types, &block)
        search = session.new_search(*types, &block)
        if search_collections.present?
          search.build do
            adjust_solr_params do |params|
              params[:collection] = search_collections.join(',')
            end
          end
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
        new_search(*types, &block).execute
      end

      def more_like_this(object, &block)
        # FIXME: should use shards
        new_more_like_this(object, &block).execute
      end

      def new_more_like_this(object, &block)
        session.new_more_like_this(object, &block)
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

      def default_init_date
        (Time.now.utc - 1.month).to_i if defined?(::Rails)
        Time.now.utc.to_i - 30 * 24 * 3600 # naive version
      end

      def default_end_date
        Time.now.utc.to_i
      end

      private

      #
      # Wrap the solr call and retries in case of ConnectionRefused or Http errors
      #
      def with_exception_handling
        retries = 0
        max_retries = 3
        begin
          yield
        rescue RSolr::Error::ConnectionRefused, RSolr::Error::Http => e
          logger.error "Error connecting to Solr #{e.message}"
          if retries < max_retries
            retries += 1
            sleep_for = 2**retries
            logger.error "Retrying Solr connection in #{sleep_for} seconds... (#{retries} of #{max_retries})"
            sleep(sleep_for)
            retry
          else
            logger.error 'Reached max Solr connection retry count.'
            raise e
          end
        end
      rescue StandardError => e
        logger.error "Exception: #{e.inspect}"
        raise e
      end

      def calculate_search_collections(date_from:, date_to:)
        date_from = Time.at(date_from).utc.to_date
        date_to = Time.at(date_to).utc.to_date
        qc = (date_from..date_to).map { |d| collection_name(year: d.year, month: d.month) }.uniq
        qc & solr.collections
        # raise IllegalSearchError, 'With TbcSessionProxy you must provide a valid list of collections' if qc.empty?
        # qc
      end

      #
      # The collection returns the collection name for the object based on time_routed_on
      # String:: collection name
      #
      def collection_for(object)
        raise NoMethodError, "Method :time_routed_on on class #{object.class} is not defined" unless object.respond_to?(:time_routed_on)
        time_routed_on = object.published_at.utc
        collection_name(year: time_routed_on.year, month: time_routed_on.month)
      end

      #
      # The collection name is based on base_name, year, month
      # String:: collection_name
      #
      def collection_name(year:, month:)
        "#{@config.collection_param('base_name')}_#{year}_#{month}"
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

      #
      # Get hostname
      #
      def get_hostname
        hostnames = (@solr.live_nodes + @config.hostnames).uniq
        # round robin policy
        @next_host_index = (@next_host_index + 1) % hostnames.size
        hostnames[@next_host_index]
      end
    end
  end
end
