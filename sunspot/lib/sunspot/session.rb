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
      @deletes = @adds = 0
    end

    # 
    # See Sunspot.new_search
    #
    def new_search(*types, &block)
      types.flatten!
      search = Search::StandardSearch.new(
        connection,
        setup_for_types(types),
        Query::StandardQuery.new(types),
        @config
      )
      search.build(&block) if block
      search
    end

    #
    # See Sunspot.search
    #
    def search(*types, &block)
      search = new_search(*types, &block)
      search.execute
    end

    # 
    # See Sunspot.new_more_like_this
    #
    def new_more_like_this(object, *types, &block)
      types[0] ||= object.class
      mlt = Search::MoreLikeThisSearch.new(
        connection,
        setup_for_types(types),
        Query::MoreLikeThisQuery.new(object, types),
        @config
      )
      mlt.build(&block) if block
      mlt
    end

    #
    # See Sunspot.more_like_this
    #
    def more_like_this(object, *types, &block)
      mlt = new_more_like_this(object, *types, &block)
      mlt.execute
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
      connection.commit
    end

    #
    # See Sunspot.optimize
    #
    def optimize
      @adds = @deletes = 0
      connection.optimize
    end

    # 
    # See Sunspot.remove
    #
    def remove(*objects, &block)
      if block
        types = objects
        conjunction = Query::Connective::Conjunction.new
        if types.length == 1
          conjunction.add_positive_restriction(TypeField.instance, Query::Restriction::EqualTo, types.first)
        else
          conjunction.add_positive_restriction(TypeField.instance, Query::Restriction::AnyOf, types)
        end
        dsl = DSL::Scope.new(conjunction, setup_for_types(types))
        Util.instance_eval_or_call(dsl, &block)
        indexer.remove_by_scope(conjunction)
      else
        objects.flatten!
        @deletes += objects.length
        objects.each do |object|
          indexer.remove(object)
        end
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
        indexer.remove_all
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
    # RSolr::Connection::Base:: The connection for this session
    #
    def connection
      @connection ||=
        self.class.connection_class.connect(:url          => config.solr.url,
                                            :read_timeout => config.solr.read_timeout,
                                            :open_timeout => config.solr.open_timeout)
    end

    def indexer
      @indexer ||= Indexer.new(connection)
    end

    def setup_for_types(types)
      if types.empty?
        raise(ArgumentError, "You must specify at least one type to search")
      end
      if types.length == 1
        Setup.for(types.first)
      else
        CompositeSetup.for(types)
      end
    end
  end
end
