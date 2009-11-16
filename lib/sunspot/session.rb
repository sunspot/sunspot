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
    def initialize(config = Configuration.build, connection = nil, master_connection = nil)
      @config = config
      yield(@config) if block_given?
      @connection = connection
      @master_connection = master_connection
      @deletes = @adds = 0
    end

    # 
    # See Sunspot.new_search
    #
    def new_search(*types)
      types.flatten!
      if types.empty?
        raise(ArgumentError, "You must specify at least one type to search")
      end
      setup =
        if types.length == 1
          Setup.for(types.first)
        else
          CompositeSetup.for(types)
          end
      Search.new(connection, setup, Query::Query.new(types), @config)
    end

    #
    # See Sunspot.search
    #
    def search(*types, &block)
      search = new_search(*types)
      search.build(&block) if block
      search.execute!
    end

    #
    # See Sunspot.index
    #
    def index(*objects)
      objects.flatten!
      @adds += objects.length
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
      @adds = @deletes = 0
      master_connection.commit
    end

    # 
    # See Sunspot.remove
    #
    def remove(*objects)
      objects.flatten!
      @deletes += objects.length
      objects.each do |object|
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
        @deletes += 1
        Indexer.remove_all(master_connection)
      else
        @deletes += classes.length
        classes.each { |clazz| indexer.remove_all(clazz) }
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
      (@deletes + @adds) > 0
    end

    # 
    # See Sunspot.commit_if_dirty
    #
    def commit_if_dirty
      commit if dirty?
    end
    
    # 
    # See Sunspot.delete_dirty?
    #
    def delete_dirty?
      @deletes > 0
    end

    # 
    # See Sunspot.commit_if_delete_dirty
    #
    def commit_if_delete_dirty
      commit if delete_dirty?
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
          connection = self.class.connection_class.connect(
            :url => config.solr.url
          )
          connection
        end
    end

    # 
    # Retrieve the Solr connection to the master for this session, creating one
    # if it does not already exist.
    #
    # ==== Returns
    #
    # Solr::Connection:: The connection for this session
    #
    def master_connection
      @master_connection ||=
        begin
          if config.master_solr.url && config.master_solr.url != config.solr.url
            master_connection = self.class.connection_class.new(
              RSolr::Connection::NetHttp.new(:url => config.master_solr.url)
            )
            master_connection
          else
            connection
          end
        end
    end

    def indexer
      @indexer ||= Indexer.new(master_connection)
    end
  end
end
