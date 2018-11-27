# frozen_string_literal: true

module Sunspot
  class AdminSession < Session
    #
    # AdminSession connect direclty to the admin Solr endpoint
    # to handle admin stuff like collections listing, creation, etc...
    #

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

    def initialize(config, refresh_every: 1800)
      @initialized_at = Time.now
      @refresh_every = refresh_every
      @config = config
    end

    #
    # Return the appropriate admin session
    def session
      c = Sunspot::Configuration.build
      host_port = @config.hostnames[rand(@config.hostnames.size)].split(':')
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
    # Return all collections. Refreshing every @refresh_every (default: 30.min)
    # Array:: collections
    def collections(force: false)
      with_cache('LIST', force: force, key: 'CACHE_SOLR_COLLECTIONS') do |resp|
        resp['collections']
      end
    end

    #
    # Return all collections. Refreshing every @refresh_every (default: 30.min)
    # Array:: collections
    def live_nodes(force: false)
      with_cache('CLUSTERSTATUS', force: force, key: 'CACHE_SOLR_LIVE_NODES') do |resp|
        resp['cluster']['live_nodes'].map do |node|
          host_port = node.split(':')
          if host_port.size == 2
            port = host_port.last.gsub('_solr', '')
            "#{host_port.first}:#{port}"
          else
            node
          end
        end
      end
    end

    #
    # Return { status:, time: sec}.
    # https://lucene.apache.org/solr/guide/6_6/collections-api.html
    #
    def create_collection(collection_name:)
      collection_conf = @config.collection
      params = {}
      params[:action] = 'CREATE'
      params[:name] = collection_name
      CREATE_COLLECTION_MAP.each do |k, v|
        ks = k.to_s
        params[v] = collection_conf[ks] unless collection_conf[ks].nil?
      end
      begin
        response = connection.get :collections, params: params
        collections(force: true)
        return { status: 200, time: response['responseHeader']['QTime'] }
      rescue RSolr::Error::Http => e
        return { status: e.response[:status], message: e.message[/^.*$/] }
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
        return { status: e.response[:status], message: e.message[/^.*$/] }
      end
    end

    private

    # Helper function for solr caching
    def with_cache(action, force: false, key: "#{CACHE_SOLR}_#{action}")
      if defined?(::Rails.cache)
        ::Rails.cache.delete(key) if force
        ::Rails.cache.fetch(key, expires_in: @refresh_every) do
          yield(connection.get(:collections, params: { action: action }))
        end
      else
        if force || (Time.now - @initialized_at) > @refresh_every
          @initialized_at = Time.now
          @cached    ||= {}
          @cached[key] = nil
        end
        @cached      ||= {}
        @cached[key] ||=
          yield(connection.get(:collections, params: { action: action }))
      end
    end
  end
end
