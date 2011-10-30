require 'set'
require 'time'
require 'date'
require 'enumerator'
require 'cgi'
begin
  require 'rsolr'
rescue LoadError
  require 'rubygems'
  require 'rsolr'
end

require File.join(File.dirname(__FILE__), 'light_config')

%w(util adapters configuration setup composite_setup text_field_setup field
   field_factory data_extractor indexer query search session session_proxy
   type dsl class_set).each do |filename|
  require File.join(File.dirname(__FILE__), 'sunspot', filename)
end

#
# The Sunspot module provides class-method entry points to most of the
# functionality provided by the Sunspot library. Internally, the Sunspot
# singleton class contains a (non-thread-safe!) instance of Sunspot::Session,
# to which it delegates most of the class methods it exposes. In the method
# documentation below, this instance is referred to as the "singleton session".
#
# Though the singleton session provides a convenient entry point to Sunspot,
# it is by no means required to use the Sunspot class methods. Multiple sessions
# may be instantiated and used (if you need to connect to multiple Solr
# instances, for example.)
#
# Note that the configuration of classes for index/search (the +setup+
# method) is _not_ session-specific, but rather global.
#
module Sunspot
  UnrecognizedFieldError = Class.new(StandardError)
  UnrecognizedRestrictionError = Class.new(StandardError)
  NoAdapterError = Class.new(StandardError)
  NoSetupError = Class.new(StandardError)
  IllegalSearchError = Class.new(StandardError)
  NotImplementedError = Class.new(StandardError)

  autoload :Installer, File.join(File.dirname(__FILE__), 'sunspot', 'installer')

  # Array to track classes that have been set up for searching.
  # Used by, e.g., Sunspot::Rails for reindexing all searchable classes.
  @searchable = ClassSet.new

  class <<self
    # 
    # Clients can inject a session proxy, allowing them to implement custom
    # session-management logic while retaining the Sunspot singleton API as
    # an available interface. The object assigned to this attribute must
    # respond to all of the public methods of the Sunspot::Session class.
    #
    attr_writer :session

    #
    # Access the list of classes set up to be searched.
    #
    attr_reader :searchable

    # Configures indexing and search for a given class.
    #
    # ==== Parameters
    #
    # clazz<Class>:: class to configure
    #
    # ==== Example
    #
    #   Sunspot.setup(Post) do
    #     text :title, :body
    #     string :author_name
    #     integer :blog_id
    #     integer :category_ids
    #     float :average_rating, :using => :ratings_average
    #     time :published_at
    #     string :sort_title do
    #       title.downcase.sub(/^(an?|the)\W+/, ''/) if title = self.title
    #     end
    #   end
    #
    # ====== Attribute Fields vs. Virtual Fields
    #
    # Attribute fields call a method on the indexed object and index the
    # return value. All of the fields defined above except for the last one are
    # attribute fields. By default, the field name will also be the attribute
    # used; this can be overriden with the +:using+ option, as in
    # +:average_rating+ above. In that case, the attribute +:ratings_average+
    # will be indexed with the field name +:average_rating+.
    #
    # +:sort_title+ is a virtual field, which evaluates the block inside the
    # context of the instance being indexed, and indexes the value returned
    # by the block. If the block you pass takes an argument, it will be passed
    # the instance rather than being evaluated inside of it; so, the following
    # example is equivalent to the one above (assuming #title is public):
    #
    #   Sunspot.setup(Post) do
    #     string :sort_title do |post|
    #       post.title.downcase.sub(/^(an?|the)\W+/, ''/) if title = self.title
    #     end
    #   end
    #
    # ===== Field Types
    #
    # The available types are:
    # 
    # * +text+
    # * +string+
    # * +integer+
    # * +float+
    # * +time+
    # * +boolean+
    #
    # Note that the +text+ type behaves quite differently from the others -
    # this is the type that is indexed as fulltext, and is searched using the
    # +keywords+ method inside the search DSL. Text fields cannot have
    # restrictions set on them, nor can they be used in order statements or
    # for facets. All other types are indexed literally, and thus can be used
    # for all of those operations. They will not, however, be searched in
    # fulltext. In this way, Sunspot provides a complete barrier between
    # fulltext fields and value fields.
    #
    # It is fine to specify a field both as a text field and a string field;
    # internally, the fields will have different names so there is no danger
    # of conflict.
    # 
    # ===== Dynamic Fields
    # 
    # For use cases which have highly dynamic data models (for instance, an
    # open set of key-value pairs attached to a model), it may be useful to
    # defer definition of fields until indexing time. Sunspot exposes dynamic
    # fields, which define a data accessor (either attribute or virtual, see
    # above), which accepts a hash of field names to values. Note that the field
    # names in the hash are internally scoped to the base name of the dynamic
    # field, so any time they are referred to, they are referred to using both
    # the base name and the dynamic (runtime-specified) name.
    #
    # Dynamic fields are speficied in the setup block using the type name
    # prefixed by +dynamic_+. For example:
    # 
    #   Sunspot.setup(Post) do
    #     dynamic_string :custom_values do
    #       key_value_pairs.inject({}) do |hash, key_value_pair|
    #         hash[key_value_pair.key.to_sym] = key_value_pair.value
    #       end
    #     end
    #   end
    # 
    # If you later wanted to facet all of the values for the key "cuisine",
    # you could issue:
    # 
    #   Sunspot.search(Post) do
    #     dynamic :custom_values do
    #       facet :cuisine
    #     end
    #   end
    # 
    # In the documentation, +:custom_values+ is referred to as the "base name" -
    # that is, the one specified statically - and +:cuisine+ is referred to as
    # the dynamic name, which is the part that is specified at indexing time.
    # 
    def setup(clazz, &block)
      Sunspot.searchable << clazz
      Setup.setup(clazz, &block)
    end

    # Indexes objects on the singleton session.
    #
    # ==== Parameters
    #
    # objects...<Object>:: objects to index (may pass an array or varargs)
    #
    # ==== Example
    #
    #   post1, post2 = new Array(2) { Post.create }
    #   Sunspot.index(post1, post2)
    #
    # Note that indexed objects won't be reflected in search until a commit is
    # sent - see Sunspot.index! and Sunspot.commit
    #
    def index(*objects)
      session.index(*objects)
    end

    # Indexes objects on the singleton session and commits immediately.
    #
    # See: Sunspot.index and Sunspot.commit
    #
    # ==== Parameters
    #
    # objects...<Object>:: objects to index (may pass an array or varargs)
    #
    def index!(*objects)
      session.index!(*objects)
    end

    # Commits the singleton session
    #
    # When documents are added to or removed from Solr, the changes are
    # initially stored in memory, and are not reflected in Solr's existing
    # searcher instance. When a commit message is sent, the changes are written
    # to disk, and a new searcher is spawned. Commits are thus fairly
    # expensive, so if your application needs to index several documents as part
    # of a single operation, it is advisable to index them all and then call
    # commit at the end of the operation.
    #
    # Note that Solr can also be configured to automatically perform a commit
    # after either a specified interval after the last change, or after a
    # specified number of documents are added. See
    # http://wiki.apache.org/solr/SolrConfigXml
    #
    def commit
      session.commit
    end

    # Optimizes the index on the singletion session.
    #
    # Frequently adding and deleting documents to Solr, leaves the index in a
    # fragmented state. The optimize command merges all index segments into 
    # a single segment and removes any deleted documents, making it faster to 
    # search. Since optimize rebuilds the index from scratch, it takes some 
    # time and requires double the space on the hard disk while it's rebuilding.
    # Note that optimize also commits.
    def optimize
      session.optimize
    end

    # 
    # Create a new Search instance, but do not execute it immediately. Generally
    # you will want to use the #search method to build and execute searches in
    # one step, but if you are building searches piecemeal you may call
    # #new_search and then call #build one or more times to add components to
    # the query.
    #
    # ==== Example
    #
    #   search = Sunspot.new_search do
    #     with(:blog_id, 1)
    #   end
    #   search.build do
    #     keywords('some keywords')
    #   end
    #   search.build do
    #     order_by(:published_at, :desc)
    #   end
    #   search.execute
    #
    #   # This is equivalent to:
    #   Sunspot.search do
    #     with(:blog_id, 1)
    #     keywords('some keywords')
    #     order_by(:published_at, :desc)
    #   end
    # 
    # ==== Parameters
    #
    # types<Class>...::
    #   One or more types to search for. If no types are passed, all
    #   configured types will be searched for.
    #
    # ==== Returns
    #
    # Sunspot::Search::
    #   Search object, not yet executed. Query parameters can be added manually;
    #   then #execute should be called.
    # 
    def new_search(*types, &block)
      session.new_search(*types, &block)
    end


    # Search for objects in the index.
    #
    # ==== Parameters
    #
    # types<Class>...::
    #   One or more types to search for. If no types are passed, all
    #   configured types will be searched.
    #
    # ==== Returns
    #
    # Sunspot::Search:: Object containing results, facets, count, etc.
    #
    # The fields available for restriction, ordering, etc. are those that meet
    # the following criteria:
    #
    # * They are not of type +text+.
    # * They are defined for at least one of the classes being searched
    # * They have the same data type for all of the classes being searched.
    # * They have the same multiple flag for all of the classes being searched.
    # * They have the same stored flag for all of the classes being searched.
    #
    # The restrictions available are the constants defined in the
    # Sunspot::Restriction class. The standard restrictions are:
    #
    #   with(:field_name).equal_to(value)
    #   with(:field_name, value) # shorthand for above
    #   with(:field_name).less_than(value)
    #   with(:field_name).greater_than(value)
    #   with(:field_name).between(value1..value2)
    #   with(:field_name).any_of([value1, value2, value3])
    #   with(:field_name).all_of([value1, value2, value3])
    #   without(some_instance) # exclude that particular instance
    #
    # +without+ can be substituted for +with+, causing the restriction to be
    # negated. In the last example above, only +without+ works, as it does not
    # make sense to search only for an instance you already have.
    #
    # Equality restrictions can take +nil+ as a value, which restricts the
    # results to documents that have no value for the given field. Passing +nil+
    # as a value to other restriction types is illegal. Thus:
    #
    #   with(:field_name, nil) # ok
    #   with(:field_name).equal_to(nil) # ok
    #   with(:field_name).less_than(nil) # bad
    #
    # ==== Example
    #
    #   Sunspot.search(Post) do
    #     keywords 'great pizza'
    #     with(:published_at).less_than Time.now
    #     with :blog_id, 1
    #     without current_post
    #     facet :category_ids
    #     order_by :published_at, :desc
    #     paginate 2, 15
    #   end
    #  
    # If the block passed to #search takes an argument, that argument will
    # present the DSL, and the block will be evaluated in the calling context.
    # This will come in handy for building searches using instance data or
    # methods, e.g.:
    #
    #   Sunspot.search(Post) do |query|
    #     query.with(:blog_id, @current_blog.id)
    #   end
    #
    # See Sunspot::DSL::Search, Sunspot::DSL::Scope, Sunspot::DSL::FieldQuery
    # and Sunspot::DSL::StandardQuery for the full API presented inside the
    # block.
    #
    def search(*types, &block)
      session.search(*types, &block)
    end

    def new_more_like_this(object, *types, &block)
      session.new_more_like_this(object, *types, &block)
    end

    # 
    # Initiate a MoreLikeThis search. MoreLikeThis is a special type of search
    # that finds similar documents using fulltext comparison. The fields to be
    # compared are `text` fields set up with the `:more_like_this` option set to
    # `true`. By default, more like this returns objects of the same type as the
    # object used for comparison, but a list of types can optionally be passed
    # to this method to return similar documents of other types. This will only
    # work for types that have common fields.
    #
    # The DSL for MoreLikeThis search exposes several methods for setting
    # options specific to this type of search. See the
    # Sunspot::DSL::MoreLikeThis class and the MoreLikeThis documentation on
    # the Solr wiki: http://wiki.apache.org/solr/MoreLikeThis
    #
    # MoreLikeThis searches have all of the same scoping, ordering, and faceting
    # functionality as standard searches; the only thing you can't do in a MLT
    # search is fulltext matching (since the MLT itself is a fulltext query).
    #
    # ==== Example
    #
    #   post = Post.first
    #   Sunspot.more_like_this(post, Post, Page) do
    #     fields :title, :body
    #     with(:updated_at).greater_than(1.month.ago)
    #     facet(:category_ids)
    #   end
    #
    #
    def more_like_this(object, *types, &block)
      session.more_like_this(object, *types, &block)
    end

    # Remove objects from the index. Any time an object is destroyed, it must
    # be removed from the index; otherwise, the index will contain broken
    # references to objects that do not exist, which will cause errors when
    # those objects are matched in search results.
    #
    # If a block is passed, it is evaluated as a search scope; in this way,
    # documents can be removed by an arbitrary query. In this case, the
    # arguments to the method should be the classes to run the query on.
    #
    # ==== Parameters
    #
    # objects...<Object>::
    #   Objects to remove from the index (may pass an array or varargs)
    #
    # ==== Example (remove a document)
    #
    #   post.destroy
    #   Sunspot.remove(post)
    #
    # ==== Example (remove by query)
    #
    #   Sunspot.remove(Post) do
    #     with(:created_at).less_than(Time.now - 14.days)
    #   end
    #
    def remove(*objects, &block)
      session.remove(*objects, &block)
    end

    # 
    # Remove objects from the index and immediately commit. See Sunspot.remove
    #
    # ==== Parameters
    #
    # objects...<Object>:: Objects to remove from the index
    #
    def remove!(*objects)
      session.remove!(*objects)
    end

    # 
    # Remove an object from the index using its class name and primary key.
    # Useful if you know this information and want to remove an object without
    # instantiating it from persistent storage
    #
    # ==== Parameters
    #
    # clazz<Class>:: Class of the object, or class name as a string or symbol
    # id::
    #   Primary key of the object. This should be the same id that would be
    #   returned by the class's instance adapter.
    #
    def remove_by_id(clazz, id)
      session.remove_by_id(clazz, id)
    end

    # 
    # Remove an object by class name and primary key, and immediately commit.
    # See #remove_by_id and #commit
    #
    def remove_by_id!(clazz, id)
      session.remove_by_id!(clazz, id)
    end

    # Remove all objects of the given classes from the index. There isn't much
    # use for this in general operations but it can be useful for maintenance,
    # testing, etc. If no arguments are passed, remove everything from the
    # index.
    #
    # ==== Parameters
    #
    # classes...<Class>::
    #   classes for which to remove all instances from the index (may pass an
    #   array or varargs)
    #
    # ==== Example
    #
    #   Sunspot.remove_all(Post, Blog)
    #
    def remove_all(*classes)
      session.remove_all(*classes)
    end

    # 
    # Remove all objects of the given classes from the index and immediately
    # commit. See Sunspot.remove_all
    #
    # ==== Parameters
    #
    # classes...<Class>::
    #   classes for which to remove all instances from the index
    def remove_all!(*classes)
      session.remove_all!(*classes)
    end

    # 
    # Process all adds in a batch. Any Sunspot adds initiated inside the block
    # will be sent in bulk when the block finishes. Useful if your application
    # initiates index adds from various places in code as part of a single
    # operation; doing a batch add will give better performance.
    #
    # ==== Example
    #
    #   Sunspot.batch do
    #     post = Post.new
    #     Sunspot.add(post)
    #     comment = Comment.new
    #     Sunspot.add(comment)
    #   end
    #
    # Sunspot will send both the post and the comment in a single request.
    #
    def batch(&block)
      session.batch(&block)
    end

    #
    # True if documents have been added, updated, or removed since the last
    # commit.
    #
    # ==== Returns
    #
    # Boolean:: Whether there have been any updates since the last commit
    #
    def dirty?
      session.dirty?
    end

    # 
    # Sends a commit if the session is dirty (see #dirty?).
    #
    def commit_if_dirty
      session.commit_if_dirty
    end
    
    #
    # True if documents have been removed since the last commit.
    #
    # ==== Returns
    #
    # Boolean:: Whether there have been any deletes since the last commit
    #
    def delete_dirty?
      session.delete_dirty?
    end

    # 
    # Sends a commit if the session has deletes since the last commit (see #delete_dirty?).
    #
    def commit_if_delete_dirty
      session.commit_if_delete_dirty
    end
    
    # Returns the configuration associated with the singleton session. See
    # Sunspot::Configuration for details.
    #
    # ==== Returns
    #
    # LightConfig::Configuration:: configuration for singleton session
    #
    def config
      session.config
    end

    # 
    # Resets the singleton session. This is useful for clearing out all
    # static data between tests, but probably nowhere else.
    #
    # ==== Parameters
    #
    # keep_config<Boolean>::
    #   Whether to retain the configuration used by the current singleton
    #   session. Default false.
    #
    def reset!(keep_config = false)
      config =
        if keep_config
          session.config
        else
          Configuration.build
        end
      @session = Session.new(config)
    end

    # 
    # Get the singleton session, creating it if none yet exists.
    #
    # ==== Returns
    #
    # Sunspot::Session:: the singleton session
    #
    def session #:nodoc:
      @session ||= Session.new
    end
  end
end
