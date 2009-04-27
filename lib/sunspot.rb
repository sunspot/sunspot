gem 'solr-ruby'
gem 'extlib'
require 'solr'
require 'extlib'
require File.join(File.dirname(__FILE__), 'light_config')

%w(adapters builder restriction configuration setup field facets indexer query search facet facet_row session type util dsl).each do |filename|
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
    #     float :average_rating
    #     time :published_at
    #     string :sort_title do
    #       title.downcase.sub(/^(an?|the)\W+/, ''/) if title = self.title
    #     end
    #   end
    #
    # All of the calls except for the last one will simply index the value
    # returned by the given method. The last call is for a virtual field,
    # which evalues the block inside the context of the instance being indexed,
    # and indexes the value returned by the block.
    #
    # The available types are:
    # 
    # * +text+
    # * +string+
    # * +integer+
    # * +float+
    # * +time+
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

    # Search for objects in the index.  +search+ provides a rich DSL for
    # constructing queries - see Sunspot::DSL::Query for the full API.
    #
    # ==== Parameters
    #
    # types<Class>...::
    #   Zero, one, or more types to search for. If no types are passed, all
    #   configured types will be searched.
    #
    # ==== Returns
    #
    # Sunspot::Search:: Object containing results, facets, counts, etc.
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
