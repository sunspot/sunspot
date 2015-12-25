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
        attr_accessor :scopes
        attr_reader :select

        def initialize(clazz)
          super(clazz)
          @inherited_attributes = [:include, :select, :scopes]
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
          @clazz.where(@clazz.primary_key => id).merge(scope_for_load).first
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
          @clazz.where(@clazz.primary_key => ids).merge(scope_for_load)
        end
        
        private
        
        def scope_for_load
          scope = relation
          scope = scope.includes(@include) if @include.present?
          scope = scope.select(@select)    if @select.present?
          Array.wrap(@scopes).each do |s|
            scope = scope.send(s)
          end
          scope 
        end

        # COMPATIBILITY: Rails 4 has deprecated the 'scoped' method in favour of 'all'
        def relation
          ::Rails.version >= '4' ? @clazz.all : @clazz.scoped
        end
      end
    end
  end
end
