module Sunspot #:nodoc:
  module Rails #:nodoc:
    #
    # This module adds the ability for an ActiveRecord to trigger Solr indexing
    # of associated ActiveRecord models. The associated models are indexed
    # after the base model is saved or destroyed.
    #
    # Note that the trigging model does not need to be Searchable, but
    # the associatd model(s) do need to be Searchable.
    #
    module IndexRelated
      class <<self
        def included(base) #:nodoc:
          base.module_eval do
            extend(ActsAsMethods)
          end
        end
      end

      module ActsAsMethods
        #
        # Configures the ActiveRecord to trigger indexing of the specified
        # associated models when this models is saved or destroyed.
        #
        # ==== Options (+options+)
        # All options are passed to after_save and after_destroy. For example:
        #
        # :if<Mixed>::
        #   Only index associated models if the method, proc or string evaluates
        #   to true (e.g. <code>:if => :should_index?</code> or <code>:if =>
        #   proc { |model| model.foo > 2 }</code>). Multiple constraints can be
        #   specified by passing an array (e.g. <code>:if => [:method1, :method2]
        #   </code>).
        # :unless<Mixed>::
        #   Only index associated models if the method, proc or string evaluates
        #   to false (e.g. <code>:unless => :should_index?</code> or <code>:unless =>
        #   proc { |model| model.foo > 2 }</code>). Multiple constraints can be
        #   specified by passing an array (e.g. <code>:unless => [:method1, :method2]
        #   </code>).
        #
        # ==== Example
        #
        #   class Post < ActiveRecord::Base
        #     belongs_to :blog
        #     belongs_to :author
        #
        #     index_related :blog, :author, if: :published?
        #   end
        #
        #

        def index_related(*args)
          include InstanceMethods

          callback_options = args.last.is_a?(::Hash) ? args.pop : {}

          class_attribute :indexable
          self.indexable = *args

          after_save :index_related, callback_options
          after_destroy :index_related, callback_options
        end
      end

      module InstanceMethods
        private
        def index_related
          indexable.each do |related_attribute|
            related_model = send(related_attribute)
            Sunspot.index!(related_model) if related_model
          end
        end
      end
    end
  end
end
