module Sunspot
  # 
  # A Sunspot session encapsulates a connection to Solr and a set of
  # configuration choices. Though users of Sunspot may manually instantiate
  # Session objects, in the general case it's easier to use the singleton
  # stored in the Sunspot module. Since the Sunspot module provides all of
  # the instance methods of Session as class methods, they are not documented
  # again here.
  #
  class Session
    attr_reader :config

    # 
    # Sessions are initialized with a Sunspot configuration and a Solr
    # connection. Usually you will want to stick with the default arguments
    # when instantiating your own sessions.
    #
    def initialize(config = Configuration.build, connection = nil)
      @config = config
      yield(@config) if block_given?
      @connection = connection
    end

    #
    # See Sunspot.search
    #
    def search(*types, &block)
      types.flatten!
      Search.new(connection, @config, *types, &block).execute!
    end

    #
    # See Sunspot.index
    #
    def index(*objects)
      objects.flatten!
      for object in objects
        setup_for(object).indexer(connection).add(object)
      end
    end

    # 
    # See Sunspot.index!
    #
    def index!(*objects)
      index(*objects)
      commit
    end

    #
    # See Sunspot.commit!
    #
    def commit
      connection.commit
    end

    # 
    # See Sunspot.remove
    #
    def remove(*objects)
      objects.flatten!
      for object in objects
        setup_for(object).indexer(connection).remove(object)
      end
    end

    #
    # See Sunspot.remove_all
    #
    def remove_all(*classes)
      classes.flatten!
      if classes.empty?
        Indexer.remove_all(connection)
      else
        for clazz in classes
          Setup.for(clazz).indexer(connection).remove_all
        end
      end
    end

    private

    # 
    # Get the Setup object for the given object's class.
    #
    # ==== Parameters
    #
    # object<Object>:: The object whose setup is to be retrieved
    #
    # ==== Returns
    #
    # Sunspot::Setup:: The setup for the object's class
    #
    def setup_for(object)
      Setup.for(object.class) || raise(ArgumentError, "Sunspot is not configured for #{object.class.inspect}")
    end

    # 
    # Retrieve the Solr connection for this session, creating one if it does not
    # already exist.
    #
    # ==== Returns
    #
    # Solr::Connection:: The connection for this session
    #
    def connection
      @connection ||= Solr::Connection.new(config.solr.url)
    end
  end
end
