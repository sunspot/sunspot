gem 'solr-ruby'
gem 'extlib'
require 'solr'
require 'extlib'
require File.join(File.dirname(__FILE__), 'light_config')

%w(adapters restriction configuration setup field facets indexer query search facet facet_row session type util dsl).each do |filename|
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
# Note that the configuration of classes for index/search (the +configure+
# method) is _not_ session-specific, but rather global.
#
module Sunspot
  UnrecognizedFieldError = Class.new(Exception)
  UnrecognizedRestrictionError = Class.new(Exception)

  class <<self
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
    def setup(clazz, &block)
      Setup.setup(clazz, &block)
    end

    # Indexes objects on the singleton session.
    #
    # ==== Parameters
    #
    # objects...<Object>:: objects to index
    #
    # ==== Example
    #
    #   post1, post2 = Array(2) { Post.create }
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
    # objects...<Object>:: objects to index
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

    # Search for objects in the index.
    #
    # ==== Parameters
    #
    # types<Class>...::
    #   Zero, one, or more types to search for. If no types are passed, all
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
    # * They are defined for all of the classes being searched
    # * They have the same data type for all of the classes being searched
    # * They have the same multiple flag for all of the classes being searched.
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
    # See Sunspot::DSL::Query for the full API presented inside the block.
    #
    def search(*types, &block)
      session.search(*types, &block)
    end

    # Remove objects from the index. Any time an object is destroyed, it must
    # be removed from the index; otherwise, the index will contain broken
    # references to objects that do not exist, which will cause errors when
    # those objects are matched in search results.
    #
    # ==== Parameters
    #
    # objects...<Object>:: Objects to remove from the index
    #
    # ==== Example
    #
    #   post.destroy
    #   Sunspot.remove(post)
    #
    def remove(*objects)
      session.remove(*objects)
    end

    # Remove all objects of the given classes from the index. There isn't much
    # use for this in general operations but it can be useful for maintenance,
    # testing, etc.
    #
    # ==== Parameters
    #
    # classes...<Class>::
    #   classes for which to remove all instances from the index
    #
    # ==== Example
    #
    #   Sunspot.remove_all(Post, Blog)
    #
    def remove_all(*classes)
      session.remove_all(*classes)
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
    def reset!
      @session = nil
    end

    private

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
