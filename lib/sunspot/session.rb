module Sunspot
  class Session
    attr_reader :config

    def initialize(config = Sunspot::Configuration.build, connection = nil)
      @config = config
      yield(@config) if block_given?
      @connection = connection
    end

    def search(*types, &block)
      ::Sunspot::Search.new(connection, *types, &block).execute!
    end

    def index(*objects)
      for object in objects
        ::Sunspot::Indexer.add(connection, object)
      end
    end

    private

    def connection
      @connection ||= Solr::Connection.new(config.solr.url, :autocommit => :on)
    end
  end
end
