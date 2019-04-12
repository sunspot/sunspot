# encoding: UTF-8
# frozen_string_literal: true

require File.join(File.dirname(__FILE__), '..', 'fault_policy')

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
    # * remove_all with an argument
    # * remove_all! with an argument
    # * atomic_update with arguments
    # * atomic_update! with arguments
    #
    class TbcSessionProxy < AbstractSessionProxy
      not_supported :batch, :atomic_update, :atomic_update!

      attr_reader :solr, :config

      include FaultPolicy

      def initialize(
        config: Sunspot::Configuration.build,
        date_from: default_init_date,
        date_to: default_end_date,
        fn_collection_filter: ->(collections) { collections } # predicate filter for collection
      )
        validate_config(config)

        @config = config
        @date_from = date_from
        @date_to = date_to
        @faulty_hosts = {}
        @host_index = 0
        @solr = Admin::AdminSession.new(config: config)
        @fn_collection_filter = fn_collection_filter
      end

      #
      # Return a session.
      #
      def session(collection: nil)
        default_collection = "#{@config.collection['base_name']}_default"
        solr.create_collection(collection_name: default_collection) unless solr.collections.find { |c| c == default_collection }.present?
        gen_session("/solr/#{collection || default_collection}")
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

      def session_for_collection(collection)
        # If collection is not present, create it!
        solr.create_collection(collection_name: collection) unless solr.collections.include?(collection)
        gen_session("/solr/#{collection}")
      end

      #
      # Return the collections that match the current time range
      # and that are filtered using fn_collection_filter function
      #
      def search_collections
        collections = @fn_collection_filter.call(
          calculate_search_collections(
            date_from: @date_from,
            date_to: @date_to
          )
        )
        filter_with_solr_eq(collections)
      end

      #
      # Return all collections sessions.
      #
      def all_sessions
        @sessions = []
        solr.collections(force: true).select { |c| c.start_with?(@config.collection['base_name']) }.each do |col|
          @sessions << gen_session("/solr/#{col}")
        end
        @sessions
      end

      #
      # See Sunspot.index
      #
      def index(*objects)
        with_exception_handling do
          using_collection_session(objects) do |session, group|
            session.index(group)
          end
        end
      end

      #
      # See Sunspot.index!
      #
      def index!(*objects)
        with_exception_handling do
          using_collection_session(objects) do |session, group|
            session.index!(group)
          end
        end
      end

      #
      # See Sunspot.remove
      #
      def remove(*objects)
        with_exception_handling do
          using_collection_session(objects) do |session, group|
            session.remove(group)
          end
        end
      end

      #
      # See Sunspot.remove!
      #
      def remove!(*objects)
        with_exception_handling do
          using_collection_session(objects) do |session, group|
            session.remove!(group)
          end
        end
      end

      #
      # See Sunspot.remove_by_id
      # you must pass clazz and collection to infer correct sessions
      #
      def remove_by_id(clazz, collection, *ids)
        with_exception_handling do
          s = session(collection: collection)
          s.remove_by_id(clazz, ids)
        end
      end

      #
      # See Sunspot.remove_by_id
      # you must pass clazz and a valid session
      #
      def remove_by_id_from_session(clazz, session, *ids)
        with_exception_handling do
          session.remove_by_id(clazz, ids)
        end
      end

      #
      # See Sunspot.remove_by_id!
      # you must pass Clazz and collection name to infer correct sessions
      #
      def remove_by_id!(clazz, collection, *ids)
        # commits only the interested sessions
        with_exception_handling do
          c_session = session(collection: collection)
          remove_by_id_from_session(clazz, c_session, ids)
          c_session.commit
        end
      end

      #
      # Commit all shards. See Sunspot.commit
      #
      def commit(soft_commit = false)
        with_exception_handling { all_sessions.each { |s| s.commit(soft_commit) }}
      end

      #
      # Optimize all shards. See Sunspot.optimize
      #
      def optimize
        with_exception_handling { all_sessions.each(&:optimize) }
      end

      #
      # Commit all dirty sessions. Only dirty sessions will be committed.
      #
      # See Sunspot.commit_if_dirty
      #
      def commit_if_dirty(soft_commit = false)
        with_exception_handling { all_sessions.each { |s| s.commit_if_dirty(soft_commit) } }
      end

      #
      # Commit all delete-dirty sessions. Only delete-dirty sessions will be
      # committed.
      #
      # See Sunspot.commit_if_delete_dirty
      #
      def commit_if_delete_dirty(soft_commit = false)
        with_exception_handling { all_sessions.each { |s| s.commit_if_delete_dirty(soft_commit) } }
      end

      #
      # See Sunspot.remove_all
      #
      def remove_all(*classes)
        with_exception_handling { all_sessions.each { |s| s.remove_all(classes) } }
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
        r_search = session.new_search(*types, &block)
        return r_search if search_collections.empty?

        # filter all valid collections
        valid_collections = calculate_valid_collections(*types)

        # build the search
        unless valid_collections.empty?
          r_search.build do
            adjust_solr_params do |params|
              params[:collection] = valid_collections.join(',')
            end
          end
        end
        r_search
      end

      def calculate_valid_collections(*types)
        searched_collections = search_collections
        valid_collections = []
        types.each do |type|
          # if the type support :select_valid_connection
          # use it to select the collection involved
          if type.method_defined?(:select_valid_collections)
            valid_collections += type.select_valid_collections(searched_collections)
          else
            valid_collections += searched_collections
          end
        end
        valid_collections.uniq
      end

      #
      # Build and execute a new Search. The search will have an extra :shards
      # param injected into the query, which will tell the Solr instance
      # referenced by the search session to search across all shards.
      #
      # See Sunspot.search
      #
      def search(*types, &block)
        with_exception_handling { return new_search(*types, &block).execute }
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

      def filter_with_solr(collections)
        solr.collections.select do |collection|
          collection.start_with?(*collections)
        end
      end

      def filter_with_solr_eq(collections)
        (collections || []) & solr.collections
      end

      def calculate_search_collections(date_from:, date_to:)
        date_from = Time.at(date_from).utc.to_date
        date_to = Time.at(date_to).utc.to_date
        qc = (date_from..date_to)
             .map { |d| collection_name(year: d.year, month: d.month) }
             .sort
             .uniq
        filter_with_solr(qc)
      end

      #
      # The collection returns the collection name for the object based on time_routed_on
      # String:: collection name
      #
      def collection_for(object)
        raise NoMethodError, "Method :time_routed_on on class #{object.class} is not defined" unless object.respond_to?(:time_routed_on)
        raise TypeError, "Type mismatch :time_routed_on on class #{object.class} is not a Time" unless object.time_routed_on.is_a?(Time)
        ts = object.time_routed_on.utc
        c_postfix = object.collection_postfix if object.respond_to?(:collection_postfix)
        collection_name(year: ts.year, month: ts.month, collection_postfix: c_postfix)
      end

      #
      # The collection name is based on base_name, year, month
      # String:: collection_name
      #
      def collection_name(year:, month:, collection_postfix: nil)
        names = []
        names << @config.collection['base_name']
        names << "#{year}_#{month}"
        names << collection_postfix if collection_postfix
        names.join('_')
      end

      #
      # Group the objects by which collection session they correspond to, and yield
      # each session and is corresponding group of objects.
      #
      def using_collection_session(objects)
        cache_sessions = {}
        grouped_objects = Hash.new { |h, k| h[k] = [] }
        objects.flatten.each do |object|
          c_name = collection_for(object)
          cache_sessions[c_name] = session_for_collection(c_name) unless cache_sessions.key?(c_name)
          grouped_objects[cache_sessions[c_name]] << object
        end
        grouped_objects.each_pair do |session, group|
          yield(session, group)
        end
      end

      #
      # Session generator
      #
      def gen_session(path)
        c = Sunspot::Configuration.build
        current_host = take_hostname
        opts = {
          host: current_host.first,
          port: current_host.last,
          path: path
        }

        c.solr.url = URI::HTTP.build(opts).to_s
        c.solr.read_timeout = @config.read_timeout
        c.solr.open_timeout = @config.open_timeout
        c.solr.proxy = @config.proxy
        Session.new(c)
      end

      def validate_config(config)
        # don't use method_defined? for config (could be an object instance)

        raise NoMethodError, 'hostname not defined for config object' unless config.methods.include?(:hostname)
        raise NoMethodError, 'hostnames not defined for config object' unless config.methods.include?(:hostnames)
        raise NoMethodError, 'collection not defined for config object' unless config.methods.include?(:collection)
        raise KeyError, 'collection config_name not defined for config object' unless config.collection['config_name'] != nil
        raise KeyError, 'collection base_name not defined for config object' unless config.collection['base_name'] != nil
        raise KeyError, 'collection num_shards not defined for config object' unless config.collection['num_shards'] != nil
        raise KeyError, 'collection replication_factor not defined for config object' unless config.collection['replication_factor'] != nil
        raise KeyError, 'collection max_shards_per_node not defined for config object' unless config.collection['max_shards_per_node'] != nil
        raise NoMethodError, 'port not defined for config object' unless config.methods.include?(:port)
        raise NoMethodError, 'proxy not defined for config object' unless config.methods.include?(:proxy)
        raise NoMethodError, 'open_timeout not defined for config object' unless config.methods.include?(:open_timeout)
        raise NoMethodError, 'read_timeout not defined for config object' unless config.methods.include?(:read_timeout)
      end
    end
  end
end
