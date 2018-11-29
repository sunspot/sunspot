# encoding: UTF-8
# frozen_string_literal: true

require 'logger'

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
        @faulty_hosts = {}
        @host_index = 0
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
        gen_session("/solr/#{col_name}")
      end

      #
      # Return the appropriate collection session for the object.
      #
      def session_for(object)
        obj_col_name = collection_for(object)
        # If collection is not present, create it!
        solr.create_collection(collection_name: obj_col_name) unless solr.collections.include?(obj_col_name)
        gen_session("/solr/#{obj_col_name}")
      end

      #
      # Return all collections sessions.
      #
      def all_sessions
        @sessions = []
        solr.collections(force: true).each do |col|
          @sessions << gen_session("/solr/#{col}")
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
        all_sessions.each { |s| s.commit(soft_commit) }
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
        all_sessions.each { |s| s.remove_all(classes) }
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
        return search if search_collections.empty?

        # filter all valid collections
        valid_collections = calculate_valid_connections(*types)

        # build the search
        unless valid_collections.empty?
          search.build do
            adjust_solr_params do |params|
              params[:collection] = valid_collections.join(',')
            end
          end
        end
        search
      end

      def calculate_valid_connections(*types)
        valid_collections = []
        types.each do |type|
          # if the type support :filter_valid_connection
          # use it to select the collection involved
          if type.respond_to?(:filter_valid_connection)
            valid_collections += type.filter_valid_connection(search_collections)
          else
            valid_collections += search_collections
          end
        end
        valid_collections.uniq!
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
          # reset counter of faulty_host for the current host
          reset_counter_faulty(@current_hostname)
        rescue RSolr::Error::ConnectionRefused, RSolr::Error::Http => e
          logger.error "Error connecting to Solr #{e.message}"

          # update the map of faulty hosts
          update_faulty_host(@current_hostname)

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
        qc = (date_from..date_to).map { |d| collection_name(year: d.year, month: d.month) }.sort.uniq
        solr.collections.select do |collection|
          collection.start_with?(*qc)
        end
      end

      #
      # The collection returns the collection name for the object based on time_routed_on
      # String:: collection name
      #
      def collection_for(object)
        raise NoMethodError, "Method :time_routed_on on class #{object.class} is not defined" unless object.respond_to?(:time_routed_on)
        raise NoMethodError, "Method :collection_postfix on class #{object.class} is not defined" unless object.respond_to?(:collection_postfix)
        raise TypeError, "Type mismatch :time_routed_on on class #{object.class} is not a DateTime" unless object.time_routed_on.is_a?(Time)
        ts = object.time_routed_on.utc
        c_prefix = object.collection_postfix
        collection_name(year: ts.year, month: ts.month, collection_postfix: c_prefix)
      end

      #
      # The collection name is based on base_name, year, month
      # String:: collection_name
      #
      def collection_name(year:, month:, collection_postfix: nil)
        names = []
        names << @config.collection['base_name']
        names << "#{year}_#{month}"
        names << collection_postfix unless collection_postfix.nil?
        names.join('_')
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
      # Get hostname (using RR policy)
      #
      def take_hostname
        # takes all the configured nodes + that one that are derived by solr live config
        hostnames = (@solr.live_nodes + seed_hosts)
                    .uniq
                    .reject { |h| is_faulty(h) }
                    .sort

        # round robin policy
        # hostname format: <ip|hostname> | <ip|hostname>:<port>
        @current_hostname = hostnames[@host_index]
        current_host = @current_hostname.split(':')
        @host_index = (@host_index + 1) % hostnames.size
        if current_host.size == 2
          [current_host.first, current_host.last.to_i]
        else
          current_host + [@config.port]
        end
      end

      #
      # Return true if an host is in fault state
      # An host is in fault state if and only if:
      # - #number of fault >= 3
      # - time in fault state is >= 1h
      #
      def is_faulty(hostname)
        @faulty_hosts.key?(hostname) &&
          @faulty_hosts[hostname].first >= 3 &&
          (Time.now - @faulty_hosts[hostname].last).to_i >= 3600
      end

      def reset_counter_faulty(hostname)
        @faulty_hosts.delete(hostname)
      end

      def update_faulty_host(hostname)
        @faulty_hosts[hostname]   ||= [0, Time.now]
        @faulty_hosts[hostname][0] += 1
        @faulty_hosts[hostname][1]  = Time.now

        if is_faulty(hostname)
          logger.error "Putting #{hostname} in fault state"
        end
      end

      def seed_hosts
        # uniform seed host
        @seed_hosts ||= @config.hostnames.map do |h|
          h = h.split(':')
          if h.size == 2
            "#{h.first}:#{h.last.to_i}"
          else
            "#{h.first}:#{@config.port}"
          end
        end
      end

      #
      # Session generator
      #
      def gen_session(path)
        c = Sunspot::Configuration.build
        current_host = take_hostname
        c.solr.url = URI::HTTP.build(
          host: current_host.first,
          port: current_host.last,
          path: path
        ).to_s
        c.solr.read_timeout = @config.read_timeout
        c.solr.open_timeout = @config.open_timeout
        c.solr.proxy = @config.proxy
        Session.new(c)
      end

      def logger
        @logger ||= ::Rails.logger
        @logger ||= Logger.new(STDOUT)
      end
    end
  end
end
