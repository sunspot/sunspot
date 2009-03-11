module Sunspot
  class Session
    attr_reader :config

    def initialize(config = Sunspot::Configuration.build, connection = nil)
      @config = config
      yield(@config) if block_given?
      @connection = connection
    end

    def search(*types, &block)
      ::Sunspot::Search.new(connection, @config, *types, &block).execute!
    end

    def index(*objects)
      for object in objects
        setup_for(object).indexer(connection).add(object)
      end
    end

    def remove(*objects)
      for object in objects
        setup_for(object).indexer(connection).remove(object)
      end
    end

    def remove_all(*classes)
      if classes.empty?
        ::Sunspot::Indexer.remove_all(connection)
      else
        classes.each do |clazz|
          ::Sunspot::Indexer.remove_all(connection, clazz)
        end
      end
    end

    private

    def setup_for(object)
      Sunspot::Setup.for(object.class) || raise(ArgumentError, "Sunspot is not configured for #{object.class.inspect}")
    end

    def connection
      @connection ||= Solr::Connection.new(config.solr.url, :autocommit => :on)
    end
  end
end
