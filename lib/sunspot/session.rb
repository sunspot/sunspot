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
      @updates = 0
    end

    # 
    # See Sunspot.new_search
    #
    def new_search(*types)
      types.flatten!
      Search.new(connection, Query.new(types, @config))
    end

    #
    # See Sunspot.search
    #
    def search(*types, &block)
      options = types.last.is_a?(Hash) ? types.pop : {}
      search = new_search(*types)
      search.query.build(&block) if block
      search.query.options = options
      search.execute!
    end

    #
    # See Sunspot.index
    #
    #--
    # FIXME The fact that we have to break this out by class and index each
    #       class separately is artificial, imposed by the fact that indexers
    #       are initialized with a particular setup, and are responsible for
    #       sending add messages to Solr. It might be worth considering a
    #       singleton indexer (per session) and have the indexer itself find
    #       the appropriate setup to use for each object.
    #
    def index(*objects)
      objects.flatten!
      @updates += objects.length
      objects.group_by { |object| object.class }.each_pair do |clazz, objs|
        indexer_for(objs.first).add(objs)
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
    # See Sunspot.commit
    #
    def commit
      @updates = 0
      connection.commit
    end

    # 
    # See Sunspot.remove
    #
    def remove(*objects)
      objects.flatten!
      @updates += objects.length
      for object in objects
        indexer_for(object).remove(object)
      end
    end

    # 
    # See Sunspot.remove!
    #
    def remove!(*objects)
      remove(*objects)
      commit
    end

    #
    # See Sunspot.remove_all
    #
    def remove_all(*classes)
      classes.flatten!
      if classes.empty?
        @updates += 1
        Indexer.remove_all(connection)
      else
        @updates += classes.length
        for clazz in classes
          Setup.for(clazz).indexer(connection).remove_all
        end
      end
    end

    # 
    # See Sunspot.remove_all!
    #
    def remove_all!(*classes)
      remove_all(*classes)
      commit
    end

    # 
    # See Sunspot.dirty?
    #
    def dirty?
      @updates > 0
    end

    # 
    # See Sunspot.commit_if_dirty
    #
    def commit_if_dirty
      commit if dirty?
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
      Setup.for(object.class) || raise(NoSetupError, "Sunspot is not configured for #{object.class.inspect}")
    end

    def indexer_for(object)
      setup_for(object).indexer(connection)
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
