module Sunspot #:nodoc:
  module Rails #:nodoc:
    #
    # This module provides Sunspot Adapter implementations for ActiveRecord
    # models.
    #
    module Adapters
      class ActiveRecordInstanceAdapter < Sunspot::Adapters::InstanceAdapter
        #
        # Return the primary key for the adapted instance
        #
        # ==== Returns
        #
        # Integer:: Database ID of model
        #
        def id
          @instance.id
        end
      end

      class ActiveRecordDataAccessor < Sunspot::Adapters::DataAccessor
        # options for the find
        attr_accessor :include
        attr_reader :select

        def initialize(clazz)
          super(clazz)
          @inherited_attributes = [:include, :select]
        end

        #
        # Set the fields to select from the database. This will be passed
        # to ActiveRecord.
        #
        # ==== Parameters
        #
        # value<Mixed>:: String of comma-separated columns or array of columns
        #
        def select=(value)
          value = value.join(', ') if value.respond_to?(:join)
          @select = value
        end

        #
        # Get one ActiveRecord instance out of the database by ID
        #
        # ==== Parameters
        #
        # id<String>:: Database ID of model to retreive
        #
        # ==== Returns
        #
        # ActiveRecord::Base:: ActiveRecord model
        #
        def load(id)
          @clazz.where(@clazz.primary_key => id).
            merge(scope_with_options).
            first
        end

        #
        # Get a collection of ActiveRecord instances out of the database by ID
        #
        # ==== Parameters
        #
        # ids<Array>:: Database IDs of models to retrieve
        #
        # ==== Returns
        #
        # Array:: Collection of ActiveRecord models
        #
        def load_all(ids)
          @clazz.where(@clazz.primary_key => ids).
            merge(scope_with_options).
            to_a
        end

        private

        def scope_with_options
          scope = relation
          scope = scope.includes(@include) unless !defined?(@include) || @include.blank?
          scope = scope.select(@select)    unless !defined?(@select)  || @select.blank?
          scope
        end

        def relation
          if ::Rails.version >= '4'
            @clazz.all
          else
            @clazz.scoped
          end
        end
      end
    end
  end
end
