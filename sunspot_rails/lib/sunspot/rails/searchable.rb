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
          base.module_eval do
            extend(ActsAsMethods)
          end
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
        # :if<Mixed>::
        #   Only index models in Solr if the method, proc or string evaluates
        #   to true (e.g. <code>:if => :should_index?</code> or <code>:if =>
        #   proc { |model| model.foo > 2 }</code>).  Models that do not match
        #   the constraint will be removed from the index upon save.  Multiple
        #   constraints can be specified by passing an array (e.g. <code>:if =>
        #   [:method1, :method2]</code>).
        # :ignore_attribute_changes_of<Array>::
        #   Define attributes, that should not trigger a reindex of that
        #   object. Usual suspects are updated_at or counters.
        # :only_reindex_attribute_changes_of<Array>::
        #   Define attributes, that are the only attributes that should
        #   trigger a reindex of that object. Useful if there are a small
        #   number of searchable attributes and a large number of attributes
        #   to ignore.
        # :include<Mixed>::
        #   Define default ActiveRecord includes, set this to allow ActiveRecord
        #   to load required associations when indexing. See ActiveRecord's 
        #   documentation on eager-loading for examples on how to set this
        #   Default: [] 
        # :unless<Mixed>::
        #   Only index models in Solr if the method, proc or string evaluates
        #   to false (e.g. <code>:unless => :should_not_index?</code> or <code>
        #   :unless => proc { |model| model.foo <= 2 }</code>).  Models that do
        #   not match the constraint will be removed from the index upon save.
        #   Multiple constraints can be specified by passing an array (e.g.
        #   <code>:unless => [:method1, :method2]</code>).
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
        def searchable(options = {}, &block)
          Sunspot.setup(self, &block)

          if searchable?
            sunspot_options[:include].concat(Util::Array(options[:include]))
          else
            extend ClassMethods
            include InstanceMethods

            class_attribute :sunspot_options

            unless options[:auto_index] == false
              before_save :mark_for_auto_indexing_or_removal
              after_save :perform_index_tasks
            end

            unless options[:auto_remove] == false
              after_destroy do |searchable|
                searchable.remove_from_index
              end
            end
            options[:include] = Util::Array(options[:include])
            
            self.sunspot_options = options
          end
        end

        # 
        # This method is defined on all ActiveRecord::Base subclasses. It
        # is false for classes on which #searchable has not been called, and
        # true for classes on which #searchable has been called.
        #
        # ==== Returns
        #
        # +false+
        #
        def searchable?
          false
        end
      end

      module ClassMethods
        def self.extended(base) #:nodoc:
          class <<base
            alias_method :search, :solr_search unless method_defined? :search
            alias_method :search_ids, :solr_search_ids unless method_defined? :search_ids
            alias_method :remove_all_from_index, :solr_remove_all_from_index unless method_defined? :remove_all_from_index
            alias_method :remove_all_from_index!, :solr_remove_all_from_index! unless method_defined? :remove_all_from_index!
            alias_method :reindex, :solr_reindex unless method_defined? :reindex
            alias_method :index, :solr_index unless method_defined? :index
            alias_method :index_orphans, :solr_index_orphans unless method_defined? :index_orphans
            alias_method :clean_index_orphans, :solr_clean_index_orphans unless method_defined? :clean_index_orphans
          end
        end
        # 
        # Search for instances of this class in Solr. The block is delegated to
        # the Sunspot.search method - see the Sunspot documentation for the full
        # API.
        #
        # ==== Example
        #
        #   Post.search(:include => [:blog]) do
        #     keywords 'best pizza'
        #     with :blog_id, 1
        #     order :updated_at, :desc
        #     facet :category_ids
        #   end
        #
        # ==== Options
        #
        # :include:: Specify associations to eager load
        # :select:: Specify columns to select from database when loading results
        #
        # ==== Returns
        #
        # Sunspot::Search:: Object containing results, totals, facets, etc.
        #
        def solr_search(options = {}, &block)
          solr_execute_search(options) do
            Sunspot.new_search(self, &block)
          end
        end

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
          solr_execute_search_ids do
            solr_search(&block)
          end
        end

        # 
        # Remove instances of this class from the Solr index.
        #
        def solr_remove_all_from_index
          Sunspot.remove_all(self)
        end

        # 
        # Remove all instances of this class from the Solr index and immediately
        # commit.
        #
        #
        def solr_remove_all_from_index!
          Sunspot.remove_all!(self)
        end

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

        #
        # Add/update all existing records in the Solr index. The
        # +batch_size+ argument specifies how many records to load out of the
        # database at a time. The default batch size is 50; if nil is passed,
        # records will not be indexed in batches. By default, a commit is issued
        # after each batch; passing +false+ for +batch_commit+ will disable
        # this, and only issue a commit at the end of the process. If associated
        # objects need to indexed also, you can specify +include+ in format 
        # accepted by ActiveRecord to improve your sql select performance
        #
        # ==== Options (passed as a hash)
        #
        # batch_size<Integer>:: Batch size with which to load records. Passing
        #                       'nil' will skip batches.  Default is 50.
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
        #   # index in batches of 50, commit after each
        #   Post.index 
        #
        #   # index all rows at once, then commit
        #   Post.index(:batch_size => nil) 
        #
        #   # index in batches of 50, commit when all batches complete
        #   Post.index(:batch_commit => false) 
        #
        #   # include the associated +author+ object when loading to index
        #   Post.index(:include => :author) 
        #
        def solr_index(opts={})
          options = {
            :batch_size => Sunspot.config.indexing.default_batch_size,
            :batch_commit => true,
            :include => self.sunspot_options[:include],
            :start => opts.delete(:first_id) || 0
          }.merge(opts)
          find_in_batch_options = {
            :include => options[:include],
            :batch_size => options[:batch_size],
            :start => options[:start]
          }
          progress_bar = options[:progress_bar]
          if options[:batch_size]
            batch_counter = 0
            find_in_batches(find_in_batch_options) do |records|
              solr_benchmark options[:batch_size], batch_counter do
                Sunspot.index(records.select { |model| model.indexable? })
                Sunspot.commit if options[:batch_commit]
              end
              # track progress
              progress_bar.increment!(records.length) if progress_bar
              batch_counter += 1
            end
          else
            records = all(:include => options[:include]).select { |model| model.indexable? }
            Sunspot.index!(records)
          end
          # perform a final commit if not committing in batches
          Sunspot.commit unless options[:batch_commit]
        end

        # 
        # Return the IDs of records of this class that are indexed in Solr but
        # do not exist in the database. Under normal circumstances, this should
        # never happen, but this method is provided in case something goes
        # wrong. Usually you will want to rectify the situation by calling
        # #clean_index_orphans or #reindex
        # 
        # ==== Options (passed as a hash)
        #
        # batch_size<Integer>:: Batch size with which to load records. Passing
        #                       Default is 1000 (from ActiveRecord).
        # 
        # ==== Returns
        #
        # Array:: Collection of IDs that exist in Solr but not in the database
        def solr_index_orphans(opts={})
          batch_size = opts[:batch_size] || Sunspot.config.indexing.default_batch_size          

          solr_page = 0
          solr_ids = []
          while (solr_page = solr_page.next)
            ids = solr_search_ids { paginate(:page => solr_page, :per_page => 1000) }.to_a
            break if ids.empty?
            solr_ids.concat ids
          end

          return solr_ids - self.connection.select_values("SELECT id FROM #{quoted_table_name}").collect(&:to_i)
        end

        # 
        # Find IDs of records of this class that are indexed in Solr but do not
        # exist in the database, and remove them from Solr. Under normal
        # circumstances, this should not be necessary; this method is provided
        # in case something goes wrong.
        #
        # ==== Options (passed as a hash)
        #
        # batch_size<Integer>:: Batch size with which to load records
        #                       Default is 50
        # 
        def solr_clean_index_orphans(opts={})
          solr_index_orphans(opts).each do |id|
            new do |fake_instance|
              fake_instance.id = id
            end.solr_remove_from_index
          end
        end

        # 
        # Classes that have been defined as searchable return +true+ for this
        # method.
        #
        # ==== Returns
        #
        # +true+
        #
        def searchable?
          true
        end
        
        def solr_execute_search(options = {})
          options.assert_valid_keys(:include, :select)
          search = yield
          unless options.empty?
            search.build do |query|
              if options[:include]
                query.data_accessor_for(self).include = options[:include]
              end
              if options[:select]
                query.data_accessor_for(self).select = options[:select]
              end
            end
          end
          search.execute
        end

        def solr_execute_search_ids(options = {})
          search = yield
          search.raw_results.map { |raw_result| raw_result.primary_key.to_i }
        end
        
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

      end

      module InstanceMethods
        def self.included(base) #:nodoc:
          base.module_eval do
            alias_method :index, :solr_index unless method_defined? :index
            alias_method :index!, :solr_index! unless method_defined? :index!
            alias_method :remove_from_index, :solr_remove_from_index unless method_defined? :remove_from_index
            alias_method :remove_from_index!, :solr_remove_from_index! unless method_defined? :remove_from_index!
            alias_method :more_like_this, :solr_more_like_this unless method_defined? :more_like_this
            alias_method :more_like_this_ids, :solr_more_like_this_ids unless method_defined? :more_like_this_ids
          end
        end
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

        # 
        # Index the model in Solr and immediately commit. See #index
        #
        def solr_index!
          Sunspot.index!(self)
        end
        
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

        # 
        # Remove the model from the Solr index and commit immediately. See
        # #remove_from_index
        #
        def solr_remove_from_index!
          Sunspot.remove!(self)
        end

        def solr_more_like_this(*args, &block)
          options = args.extract_options!
          self.class.solr_execute_search(options) do
            Sunspot.new_more_like_this(self, *args, &block)
          end
        end

        def solr_more_like_this_ids(&block)
          self.class.solr_execute_search_ids do
            solr_more_like_this(&block)
          end
        end

        def indexable?
          # options[:if] is not specified or they successfully pass
          if_passes = self.class.sunspot_options[:if].nil? ||
                      constraint_passes?(self.class.sunspot_options[:if])

          # options[:unless] is not specified or they successfully pass
          unless_passes = self.class.sunspot_options[:unless].nil? ||
                          !constraint_passes?(self.class.sunspot_options[:unless])

          if_passes and unless_passes
        end

        private

        def constraint_passes?(constraint)
          case constraint
          when Symbol
            self.__send__(constraint)
          when String
            self.__send__(constraint.to_sym)
          when Enumerable
            # All constraints must pass
            constraint.all? { |inner_constraint| constraint_passes?(inner_constraint) }
          else
            if constraint.respond_to?(:call) # could be a Proc or anything else that responds to call
              constraint.call(self)
            else
              raise ArgumentError, "Unknown constraint type: #{constraint} (#{constraint.class})"
            end
          end
        end

        def mark_for_auto_indexing_or_removal
          if indexable?
            # :if/:unless constraints pass or were not present

            @marked_for_auto_indexing =
              if !new_record? && ignore_attributes = self.class.sunspot_options[:ignore_attribute_changes_of]
                !(changed.map { |attr| attr.to_sym } - ignore_attributes).blank?
              elsif !new_record? && only_attributes = self.class.sunspot_options[:only_reindex_attribute_changes_of]
                !(changed.map { |attr| attr.to_sym } & only_attributes).blank?
              else
                true
              end

            @marked_for_auto_removal = false
          else
            # :if/:unless constraints did not pass; do not auto index and
            # actually go one step further by removing it from the index
            @marked_for_auto_indexing = false
            @marked_for_auto_removal = true
          end

          true
        end

        def perform_index_tasks
          if @marked_for_auto_indexing
            solr_index
            remove_instance_variable(:@marked_for_auto_indexing)
          elsif @marked_for_auto_removal
            solr_remove_from_index
            remove_instance_variable(:@marked_for_auto_removal)
          end
        end
      end
    end
  end
end
