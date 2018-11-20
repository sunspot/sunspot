# frozen_string_literal: true

module Sunspot
  class AdminSession
    #
    # AdminSession connect direclty to the admin Solr endpoint
    # to handle admin stuff like collections listing, creation, etc...
    #
    def initialize(config = Configuration.build, refresh_every: 1800)
      @initialized_at = Time.now
      @refresh_every = refresh_every
      @config = config.clone
      @connection = session.send(:connection)
    end

    #
    # Return the appropriate admin session
    def session
      @config.solr.url = URI::HTTP.build(
        host: @config.solr.hostnames[rand(@config.solr.hostnames.size)],
        port: @config.solr.port,
        path: '/solr/admin'
      ).to_s
      Session.new(c)
    end

    #
    # Return all collections. Refreshing every @refresh_every (default: 30.min)
    # Array:: collections
    def collections(force: false)
      if defined?(::Rails.cache)
        ::Rails.cache.delete('CACHE_SOLR_COLLECTIONS') if force
        ::Rails.cache.fetch('CACHE_SOLR_COLLECTIONS', expires_in: @refresh_every) do
          @connection.get(:collections, params: { action: 'LIST' })['collections']
        end
      else
        if force || (Time.now - @initialized_at) > @refresh_every
          @initialized_at = Time.now
          @collections = nil
        end
        @collections ||= @connection.get(:collections, params: { action: 'LIST' })['collections']
      end
    end

    #
    # Return all collections. Refreshing every @refresh_every (default: 30.min)
    # Array:: collections
    def live_nodes(force: false)
      if defined?(::Rails.cache)
        ::Rails.cache.delete('CACHE_SOLR_LIVE_NODES') if force
        ::Rails.cache.fetch('CACHE_SOLR_LIVE_NODES', expires_in: @refresh_every) do
          @connection.get(:collections, params: { action: 'CLUSTERSTATUS' })["cluster"]["live_nodes"]
        end
      else
        if force || (Time.now - @initialized_at) > @refresh_every
          @initialized_at = Time.now
          @collections = nil
        end
        @collections ||= @connection.get(:collections, params: { action: 'CLUSTERSTATUS' })["cluster"]["live_nodes"]
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
      Sunspot::Rails::Configuration::CREATE_COLLECTION_MAP.each do |k, v|
        params[v] = collection_conf[k.to_s] if collection_conf[k.to_s].present?
      end
      begin
        response = @connection.get :collections, params: params
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
        response = @connection.get :collections, params: params
        collections(force: true)
        return { status: 200, time: response['responseHeader']['QTime'] }
      rescue RSolr::Error::Http => e
        return { status: e.response[:status], message: e.message[/^.*$/] }
      end
    end
  end
end
