module Sunspot #:nodoc:
  module Rails #:nodoc:
    # 
    # This module adds Sunspot functionality to ActiveRecord models. As well as
    # providing class and instance methods, it optionally adds lifecycle hooks
    # to automatically add and remove models from the Solr index as they are
    # created and destroyed.
    #
    module Searchable
      class <<self
        def included(base) #:nodoc:
          base.module_eval { extend(ActsAsMethods) }
        end
      end

      module ActsAsMethods
        # 
        # Makes a class searchable if it is not already, or adds search
        # configuration if it is. Note that the options passed in are only used
        # the first time this method is called for a particular class; so,
        # search should be defined before activating any mixins that extend
        # search configuration.
        #
        # The block passed into this method is evaluated by the
        # <code>Sunspot.setup</code> method. See the Sunspot documentation for
        # complete information on the functionality provided by that method.
        #
        # ==== Options (+options+)
        # 
        # :auto_index<Boolean>::
        #   Automatically index models in Solr when they are saved.
        #   Default: true
        # :auto_remove<Boolean>::
        #   Automatically remove models from the Solr index when they are
        #   destroyed. <b>Setting this option to +false+ is not recommended
        #   </b>(see the README).
        # :ignore_attribute_changes_of<Array>::
        #   Define attributes, that should not trigger a reindex of that
        #   object. Usual suspects are updated_at or counters.
        #
        # ==== Example
        #
        #   class Post < ActiveRecord::Base
        #     searchable do
        #       text :title, :body
        #       string :sort_title do
        #         title.downcase.sub(/^(an?|the)/, '')
        #       end
        #       integer :blog_id
        #       time :updated_at
        #     end
        #   end
        #
        def solr_searchable(options = {}, &block)
          Sunspot.setup(self, &block)

          unless searchable?
            extend ClassMethods
            include InstanceMethods

            class_inheritable_hash :sunspot_options
            
            unless options[:auto_index] == false
              before_save :maybe_mark_for_auto_indexing
              after_save :maybe_auto_index
            end

            unless options[:auto_remove] == false
              after_destroy do |searchable|
                searchable.remove_from_index
              end
            end
          end
          self.sunspot_options = options
        end
        alias_method :searchable, :solr_searchable unless ActiveRecord::Base.respond_to? :searchable

        # 
        # This method is defined on all ActiveRecord::Base subclasses. It
        # is false for classes on which #searchable has not been called, and
        # true for classes on which #searchable has been called.
        #
        # ==== Returns
        #
        # +false+
        #
        def solr_searchable?
          false
        end
        alias_method :searchable?, :solr_searchable? unless ActiveRecord::Base.respond_to? :searchable?
      end

      module ClassMethods
        # 
        # Search for instances of this class in Solr. The block is delegated to
        # the Sunspot.search method - see the Sunspot documentation for the full
        # API.
        #
        # ==== Example
        #
        #   Post.search do
        #     keywords 'best pizza'
        #     with :blog_id, 1
        #     order :updated_at, :desc
        #     facet :category_ids
        #   end
        #
        #
        # ==== Returns
        #
        # Sunspot::Search:: Object containing results, totals, facets, etc.
        #
        def solr_search(&block)
          Sunspot.search(self, &block)
        end
        alias_method :search, :solr_search unless ActiveRecord::Base.respond_to? :search

        # 
        # Get IDs of matching results without loading the result objects from
        # the database. This method may be useful if search is used as an
        # intermediate step in a larger find operation. The block is the same
        # as the block provided to the #search method.
        #
        # ==== Returns
        #
        # Array:: Array of IDs, in the order returned by the search
        #
        def solr_search_ids(&block)
          solr_search(&block).raw_results.map { |raw_result| raw_result.primary_key.to_i }
        end
        alias_method :search_ids, :solr_search_ids unless ActiveRecord::Base.respond_to? :search_ids

        # 
        # Remove instances of this class from the Solr index.
        #
        def solr_remove_all_from_index
          Sunspot.remove_all(self)
        end
        alias_method :remove_all_from_index, :solr_remove_all_from_index unless ActiveRecord::Base.respond_to? :remove_all_from_index

        # 
        # Remove all instances of this class from the Solr index and immediately
        # commit.
        #
        #
        def solr_remove_all_from_index!
          Sunspot.remove_all!(self)
        end
        alias_method :remove_all_from_index!, :solr_remove_all_from_index! unless ActiveRecord::Base.respond_to? :remove_all_from_index!

        # 
        # Completely rebuild the index for this class. First removes all
        # instances from the index, then loads records and indexes them.
        #
        # See #index for information on options, etc.
        #
        def solr_reindex(options = {})
          solr_remove_all_from_index
          solr_index(options)
        end
        alias_method :reindex, :solr_reindex unless ActiveRecord::Base.respond_to? :reindex

        #
        # Add/update all existing records in the Solr index. The
        # +batch_size+ argument specifies how many records to load out of the
        # database at a time. The default batch size is 500; if nil is passed,
        # records will not be indexed in batches. By default, a commit is issued
        # after each batch; passing +false+ for +batch_commit+ will disable
        # this, and only issue a commit at the end of the process. If associated
        # objects need to indexed also, you can specify +include+ in format 
        # accepted by ActiveRecord to improve your sql select performance
        #
        # ==== Options (passed as a hash)
        #
        # batch_size<Integer>:: Batch size with which to load records. Passing
        #                       'nil' will skip batches.  Default is 500.
        # batch_commit<Boolean>:: Flag signalling if a commit should be done after
        #                         after each batch is indexed, default is 'true'
        # include<Mixed>:: include option to be passed to the ActiveRecord find,
        #                  used for including associated objects that need to be
        #                  indexed with the parent object, accepts all formats
        #                  ActiveRecord::Base.find does
        # first_id:: The lowest possible ID for this class. Defaults to 0, which
        #            is fine for integer IDs; string primary keys will need to
        #            specify something reasonable here.
        #
        # ==== Examples
        #   
        #   # index in batches of 500, commit after each
        #   Post.index 
        #
        #   # index all rows at once, then commit
        #   Post.index(:batch_size => nil) 
        #
        #   # index in batches of 500, commit when all batches complete
        #   Post.index(:batch_commit => false) 
        #
        #   # include the associated +author+ object when loading to index
        #   Post.index(:include => :author) 
        #
        def solr_index(opts={})
          options = { :batch_size => 500, :batch_commit => true, :include => [], :first_id => 0}.merge(opts)
          unless options[:batch_size]
            Sunspot.index!(all(:include => options[:include]))
          else
            offset = 0
            counter = 1
            record_count = count
            last_id = options[:first_id]
            while(offset < record_count)
              solr_benchmark options[:batch_size], counter do
                records = all(:include => options[:include], :conditions => ["#{table_name}.#{primary_key} > ?", last_id], :limit => options[:batch_size], :order => primary_key)
                Sunspot.index(records)
                last_id = records.last.id
              end
              Sunspot.commit if options[:batch_commit]
              offset += options[:batch_size]
              counter += 1
            end
            Sunspot.commit unless options[:batch_commit]
          end
        end
        alias_method :index, :solr_index unless ActiveRecord::Base.respond_to? :index

        # 
        # Return the IDs of records of this class that are indexed in Solr but
        # do not exist in the database. Under normal circumstances, this should
        # never happen, but this method is provided in case something goes
        # wrong. Usually you will want to rectify the situation by calling
        # #clean_index_orphans or #reindex
        # 
        # ==== Returns
        #
        # Array:: Collection of IDs that exist in Solr but not in the database
        def solr_index_orphans
          count = self.count
          indexed_ids = solr_search_ids { paginate(:page => 1, :per_page => count) }.to_set
          all(:select => 'id').each do |object|
            indexed_ids.delete(object.id)
          end
          indexed_ids.to_a
        end
        alias_method :index_orphans, :solr_index_orphans unless ActiveRecord::Base.respond_to? :index_orphans

        # 
        # Find IDs of records of this class that are indexed in Solr but do not
        # exist in the database, and remove them from Solr. Under normal
        # circumstances, this should not be necessary; this method is provided
        # in case something goes wrong.
        #
        def solr_clean_index_orphans
          solr_index_orphans.each do |id|
            new do |fake_instance|
              fake_instance.id = id
            end.solr_remove_from_index
          end
        end
        alias_method :clean_index_orphans, :solr_clean_index_orphans unless ActiveRecord::Base.respond_to? :clean_index_orphans

        # 
        # Classes that have been defined as searchable return +true+ for this
        # method.
        #
        # ==== Returns
        #
        # +true+
        #
        def solr_searchable?
          true
        end
        alias_method :searchable?, :solr_searchable? unless ActiveRecord::Base.respond_to? :searchable?
        
        protected
        
        # 
        # Does some logging for benchmarking indexing performance
        #
        def solr_benchmark(batch_size, counter,  &block)
          start = Time.now
          logger.info("[#{Time.now}] Start Indexing")
          yield
          elapsed = Time.now-start
          logger.info("[#{Time.now}] Completed Indexing. Rows indexed #{counter * batch_size}. Rows/sec: #{batch_size/elapsed.to_f} (Elapsed: #{elapsed} sec.)")
        end
        alias_method :benchmark, :solr_benchmark unless ActiveRecord::Base.respond_to? :benchmark
        
      end

      module InstanceMethods
        # 
        # Index the model in Solr. If the model is already indexed, it will be
        # updated. Using the defaults, you will usually not need to call this
        # method, as models are indexed automatically when they are created or
        # updated. If you have disabled automatic indexing (see
        # ClassMethods#searchable), this method allows you to manage indexing
        # manually.
        #
        def solr_index
          Sunspot.index(self)
        end
        alias_method :index, :solr_index unless ActiveRecord::Base.method_defined? :index

        # 
        # Index the model in Solr and immediately commit. See #index
        #
        def solr_index!
          Sunspot.index!(self)
        end
        alias_method :index!, :solr_index! unless ActiveRecord::Base.method_defined? :index!
        
        # 
        # Remove the model from the Solr index. Using the defaults, this should
        # not be necessary, as models will automatically be removed from the
        # index when they are destroyed. If you disable automatic removal
        # (which is not recommended!), you can use this method to manage removal
        # manually.
        #
        def solr_remove_from_index
          Sunspot.remove(self)
        end
        alias_method :remove_from_index, :solr_remove_from_index unless ActiveRecord::Base.method_defined? :remove_from_index

        # 
        # Remove the model from the Solr index and commit immediately. See
        # #remove_from_index
        #
        def solr_remove_from_index!
          Sunspot.remove!(self)
        end
        alias_method :remove_from_index!, :solr_remove_from_index! unless ActiveRecord::Base.method_defined? :remove_from_index!

        private

        def maybe_mark_for_auto_indexing
          @marked_for_auto_indexing =
            if !new_record? && ignore_attributes = self.class.sunspot_options[:ignore_attribute_changes_of]
              @marked_for_auto_indexing = !(changed.map { |attr| attr.to_sym } - ignore_attributes).blank?
            else
              true
            end
          true
        end

        def maybe_auto_index
          if @marked_for_auto_indexing
            solr_index
            remove_instance_variable(:@marked_for_auto_indexing)
          end
        end
      end
    end
  end
end
