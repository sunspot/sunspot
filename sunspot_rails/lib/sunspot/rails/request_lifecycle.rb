module Sunspot #:nodoc:
  module Rails #:nodoc:
    # 
    # This module adds an after_filter to ActionController::Base that commits
    # the Sunspot session if any documents have been added, changed, or removed
    # in the course of the request.
    #
    module RequestLifecycle
      class <<self
        def included(base) #:nodoc:
          subclasses = base.subclasses.map do |subclass|
            begin
              subclass.constantize
            rescue NameError
            end
          end.compact
          loaded_controllers = [base].concat(subclasses)
          # Depending on how Sunspot::Rails is loaded, there may already be
          # controllers loaded into memory that subclass this controller. In
          # this case, since after_filter uses the inheritable_attribute
          # structure, the already-loaded subclasses don't get the filters. So,
          # the below ensures that all loaded controllers have the filter.
          loaded_controllers.each do |controller|
            controller.after_filter do
              if Sunspot::Rails.configuration.auto_commit_after_request?
                Sunspot.commit_if_dirty
              elsif Sunspot::Rails.configuration.auto_commit_after_delete_request?
                Sunspot.commit_if_delete_dirty
              end
            end
          end
        end
      end
    end
  end
end
