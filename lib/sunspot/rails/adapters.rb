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
          @clazz.find(id.to_i)
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
          @clazz.find(ids.map { |id| id.to_i })
        end
      end
    end
  end
end
