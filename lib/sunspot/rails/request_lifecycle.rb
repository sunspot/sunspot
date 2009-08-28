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
          base.after_filter do
            Sunspot.commit_if_dirty if Sunspot::Rails.configuration.auto_commit_after_request?
          end
        end
      end
    end
  end
end
