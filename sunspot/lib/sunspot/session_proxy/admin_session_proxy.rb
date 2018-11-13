# frozen_string_literal: true

module Sunspot
  module SessionProxy
    class AdminSessionProxy
      def initialize
        refresh_collections
      end
      #
      # Return the appropriate shard session for the object.
      def session
        conf = Sunspot::Rails.configuration
        c = Sunspot::Configuration.build
        c.solr.url = URI::HTTP.build(
          host: conf.hostnames[rand(conf.hostnames.size)],
          port: conf.port,
          path: '/solr/admin'
        ).to_s
        c.solr.read_timeout = conf.read_timeout
        c.solr.open_timeout = conf.open_timeout
        c.solr.proxy = conf.proxy
        Session.new(c)
      end

      #
      # Return all collections.
      # Array:: collections
      def collections(force: false)
        @collections = nil if force
        @collections ||= session.connection.get(:collections, params: { action: 'LIST' })['collections']
      end

      #
      # Return { status:, time: sec}.
      # https://lucene.apache.org/solr/guide/6_6/collections-api.html
      #
      def create_collection(collection_name:)
        params = {}
        cconf = Sunspot::Rails.configuration.collection
        params[:action] = 'CREATE'
        params[:name] = collection_name
        Sunspot::Rails::Configuration::CREATE_COLLECTION_MAP.each do |k, v|
          params[v] = cconf[k.to_s] if cconf[k.to_s].present?
        end
        begin
          response = session.connection.get :collections, params: params
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
          response = session.connection.get :collections, params: params
          collections(force: true)
          return { status: 200, time: response['responseHeader']['QTime'] }
        rescue RSolr::Error::Http => e
          return { status: e.response[:status], message: e.message[/^.*$/] }
        end
      end

      private

      # Refreshing collections list every 12.hours
      def refresh_collections
        Thread.new do |thr|
          loop do
            logger.info('Refresh collections')
            collections(force: true)
            sleep 12.hours
          end
        end
      end
    end
  end
end
