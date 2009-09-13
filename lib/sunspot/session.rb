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
    class <<self
      attr_writer :connection_class #:nodoc:
      
      # 
      # For testing purposes
      #
      def connection_class #:nodoc:
        @connection_class ||= RSolr
      end
    end

    # 
    # Sunspot::Configuration object for this session
    #
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
      setup =
        if types.length == 1
          Setup.for(types.first)
        else
          CompositeSetup.for(types)
          end
      Search.new(connection, setup, Query::Query.new(types, setup, @config))
    end

    #
    # See Sunspot.search
    #
    def search(*types, &block)
      options = types.last.is_a?(Hash) ? types.pop : {}
      search = new_search(*types)
      search.build(&block) if block
      search.query.options = options
      search.execute!
    end

    #
    # See Sunspot.index
    #
    def index(*objects)
      objects.flatten!
      @updates += objects.length
      indexer.add(objects)
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
        indexer.remove(object)
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
    # See Sunspot.remove_by_id
    #
    def remove_by_id(clazz, id)
      class_name =
        if clazz.is_a?(Class)
          clazz.name
        else
          clazz.to_s
        end
      indexer.remove_by_id(class_name, id)
    end

    # 
    # See Sunspot.remove_by_id!
    #
    def remove_by_id!(clazz, id)
      remove_by_id(clazz, id)
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
          indexer.remove_all(clazz)
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

    # 
    # See Sunspot.batch
    #
    def batch
      indexer.start_batch
      yield
      indexer.flush_batch
    end

    private

    # 
    # Retrieve the Solr connection for this session, creating one if it does not
    # already exist.
    #
    # ==== Returns
    #
    # Solr::Connection:: The connection for this session
    #
    def connection
      @connection ||=
        begin
          self.class.connection_class.connect(:url => config.solr.url, :adapter => config.http_client)
          # connection = self.class.connection_class.new(
          #   RSolr::Adapter::HTTP.new(:url => config.solr.url)
          # )
          # connection.adapter.connector.adapter_name = config.http_client
          # connection
        end
    end

    def indexer
      @indexer ||= Indexer.new(connection)
    end
  end
end
