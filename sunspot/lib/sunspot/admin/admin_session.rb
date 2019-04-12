# frozen_string_literal: true

require 'logger'
require 'terminal-table'
require 'pstore'
require 'json'

module Sunspot
  module Admin
    #
    # AdminSession connect direclty to the admin Solr endpoint
    # to handle admin stuff like collections listing, creation, etc...
    #
    class AdminSession < Sunspot::Session
      include cluster_status

      CREATE_COLLECTION_MAP = {
        async: 'async',
        auto_add_replicas: 'autoAddReplicas',
        config_name: 'collection.configName',
        max_shards_per_node: 'maxShardsPerNode',
        create_node_set: 'createNodeSet',
        create_node_set_shuffle: 'createNodeSet.shuffle',
        num_shards: 'numShards',
        property_name: 'property.name',
        replication_factor: 'replicationFactor',
        router_field: 'router.field',
        router_name: 'router.name',
        rule: 'rule',
        shards: 'shards',
        snitch: 'snitch'
      }.freeze

      def initialize(config:, refresh_every: 600)
        @initialized_at = Time.now
        @refresh_every = refresh_every
        @config = config
        @replicas_not_active = []
      end

      #
      # Return the appropriate admin session
      def session
        c = Sunspot::Configuration.build
        host_port = @config.hostnames[rand(@config.hostnames.count)].split(':')
        host_port = [host_port.first, host_port.last.to_i] if host_port.size == 2
        host_port = [host_port.first, @config.port] if host_port.size == 1

        c.solr.url = URI::HTTP.build(
          host: host_port.first,
          port: host_port.last,
          path: '/solr/admin'
        ).to_s
        c.solr.read_timeout = @config.read_timeout
        c.solr.open_timeout = @config.open_timeout
        c.solr.proxy = @config.proxy
        Session.new(c)
      end

      def connection
        session.connection
      end

      #
      # Add an host to the configure hostname
      #
      def add_hostname(host)
        @config.hostnames << host
      end

      #
      # Return all collections. Refreshing every @refresh_every (10.min)
      # Array:: collections
      def collections(force: false)
        cs = with_cache(force: force, key: 'CACHE_SOLR_COLLECTIONS', default: []) do
          resp = solr_request('LIST')
          return [] if resp.nil?

          r = resp['collections']
          !r.is_a?(Array) || r.count.zero? ? [] : r
        end

        adjsut_solr_resp(cs)
      end

      #
      # Return all live nodes.
      # Array:: live_nodes
      def live_nodes(force: false)
        lnodes = with_cache(force: force, key: 'CACHE_SOLR_LIVE_NODES', default: []) do
          resp = solr_request('CLUSTERSTATUS')
          r = resp['cluster']
          return [] if r.nil?

          r = r['live_nodes'].map do |node|
            host_port = node.split(':')
            if host_port.size == 2
              port = host_port.last.gsub('_solr', '')
              "#{host_port.first}:#{port}"
            else
              node
            end
          end
          r.nil? || !r.is_a?(Array) || r.count.zero? ? [] : r
        end

        adjsut_solr_resp(lnodes)
      end

      #
      # Return { status:, time: sec}.
      # https://lucene.apache.org/solr/guide/6_6/collections-api.html
      #
      def create_collection(collection_name:)
        collection_conf = @config.collection
        config_name = collection_conf['config_name']
        params = {}
        params[:action] = 'CREATE'
        params[:name] = collection_name
        params[:config_name] = config_name unless config_name.empty?
        CREATE_COLLECTION_MAP.each do |k, v|
          ks = k.to_s
          params[v] = collection_conf[ks] unless collection_conf[ks].nil?
        end
        begin
          response = connection.get :collections, params: params
          collections(force: true)
          return { status: 200, time: response['responseHeader']['QTime'] }
        rescue RSolr::Error::Http => e
          status = e.try(:response).try(:[], :status)
          message = e.try(:message) || e.inspect
          return { status: status, message: (status ? message[/^.*$/] : message) }
        end
      end

      #
      # Return { status: , time: sec }.
      # https://lucene.apache.org/solr/guide/6_6/collections-api.html
      #
      def delete_collection(collection_name:)
        params = {}
        params[:action] = 'DELETE'
        params[:name] = collection_name
        begin
          response = connection.get :collections, params: params
          collections(force: true)
          return { status: 200, time: response['responseHeader']['QTime'] }
        rescue RSolr::Error::Http => e
          status = e.try(:response).try(:[], :status)
          message = e.try(:message) || e.inspect
          return { status: status, message: (status ? message[/^.*$/] : message) }
        end
      end

      #
      # Return { status:, time: sec}.
      # https://lucene.apache.org/solr/guide/6_6/collections-api.html
      #
      def reload_collection(collection_name:)
        params = {}
        params[:action] = 'RELOAD'
        params[:name] = collection_name
        begin
          response = connection.get :collections, params: params
          collections(force: true)
          return { status: 200, time: response['responseHeader']['QTime'] }
        rescue RSolr::Error::Http => e
          status = e.try(:response).try(:[], :status)
          message = e.try(:message) || e.inspect
          return { status: status, message: (status ? message[/^.*$/] : message) }
        end
      end

      #
      # Retrieve stats for the given collection
      #
      # @param [String] collection_name: is the collection name
      #
      # @return [Hash] stats info
      #
      def retrieve_stats_for(collection_name:)
        with_cache(force: false, key: calc_key_collection_stats(collection_name), default: {}) do
          uri = connection.uri
          c = RSolr.connect(url: "http://#{uri.host}:#{uri.port}/solr/#{collection_name}")
          begin
            response = c.get 'admin/luke', params: {
              _: (Time.now.to_f * 1000).to_i,
              numTerms: 0,
              show: 'index'
            }

            response = response['index']
            del_perc =
              response['numDocs'].to_i > 0 ? (100 * response['deletedDocs'].to_f / response['numDocs'].to_f) : 0

            {
              has_deletions: response['hasDeletions'],
              max_docs: response['maxDoc'].to_i,
              num_docs: response['numDocs'].to_i,
              deleted_docs: response['deletedDocs'].to_i,
              deleted_perc: del_perc
            }
          rescue RSolr::Error::Http => _e
            nil
          end
        end
      end

      #
      # Retrieve stats for all collections
      #
      # @param [Symbol] :as <:json, :table>
      #
      # Example: retrieve_stats(as: :table)
      #
      def retrieve_stats(as: :json)
        stats = retrieve_stats_as_json
        case as
        when :json
          stats
        when :table
          s_stats = stats.sort do |a, b|
            b[:deleted_perc] <=> a[:deleted_perc]
          end

          table = Terminal::Table.new(
            headings: ['Collection', 'Has deletions', '# Docs', '# Max Docs', '# Deleted'],
            rows: s_stats.map do |row|
              [
                row[:collection_name],
                row[:has_deletions],
                row[:num_docs],
                row[:max_docs],
                format('%d (%.2f%%)', row[:deleted_docs], row[:deleted_perc])
              ]
            end
          )
          puts table
        end
      end

      #
      # Optimize a single collection given the collection name
      #
      # @param [String] collection_name: the name of the collection
      #
      # @return [RSolrResponse]
      #
      def optimize_collection(collection_name:)
        uri = connection.uri
        c = RSolr.connect(url: "http://#{uri.host}:#{uri.port}/solr/#{collection_name}")
        begin
          response = c.get 'update', params: {
            _: (Time.now.to_f * 1000).to_i,
            commit: true,
            optimize: true
          }

          # destroy cache for that collection
          remove_key_from_cache(calc_key_collection_stats(collection_name))
          response
        rescue RSolr::Error::Http => _e
          nil
        end
      end

      #
      # Optimize all collections using a threshold of deleted docs
      #
      # @param [Number] deleted_threshold: call optimize_collection if the deleted_docs fragmentation is above the threshold
      # @param [Bool] reload: if true reload the collection after optimization
      #
      def optimize_collections(deleted_threshold: 10, reload: false)
        retrieve_stats_as_json
          .select { |e| e[:deleted_perc] > deleted_threshold }
          .each do |e|
            c = e[:collection_name]
            puts "Optimizing #{c}"
            optimize_collection(collection_name: c)
            reload_collection(collection_name: c) if reload
          end
      end

      ############################## PRIVATE ###################################

      private

      def retrieve_stats_as_json
        collections(force: true)
          .map do |c|
            retrieve_stats_for(collection_name: c).merge(collection_name: c)
          end
          .compact
      end

      def adjsut_solr_resp(resp)
        if resp.is_a?(String) && Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.4')
          Marshal.load(resp)
        else
          resp
        end
      end

      # Helper function for solr caching
      def with_cache(force: false, key:, retries: 0, max_retries: 3, default: nil, expires_in: @refresh_every)
        return default if retries >= max_retries

        r =
          if defined?(::Rails.cache)
            rails_cache(key, force, expires_in) do
              yield
            end
          else
            simple_cache(key, force, expires_in) do
              yield
            end
          end

        if r.nil?
          with_cache(
            force: true,
            key: key,
            retries: retries + 1,
            max_retries: max_retries,
            default: default
          ) { yield }
        else
          r
        end
      end

      def rails_cache(key, force, expires_in)
        ::Rails.cache.fetch(key, expires_in: expires_in, force: force) { yield }
      end

      def simple_cache(key, force, expires_in)
        if force || (Time.now - @initialized_at) > expires_in
          @initialized_at = Time.now
          @cached = {}
        end
        @cached      ||= {}
        @cached[key] ||= yield
        @cached[key]
      end

      def remove_key_from_cache(key)
        if defined?(::Rails.cache)
          ::Rails.cache.delete(key)
        else
          @cached.delete(key)
        end
      end

      def solr_request(action, extra_params: {})
        connection.get(
          :collections,
          params: { action: action, wt: 'json' }.merge(extra_params)
        )
      end

      def calc_key_collection_stats(collection_name)
        "CACHE_SOLR_COLLECTION_STATS_#{collection_name}"
      end
    end
  end
end
