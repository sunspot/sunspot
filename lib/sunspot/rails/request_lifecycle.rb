module Sunspot
  module Rails
    module RequestLifecycle
      class <<self
        def included(base)
          base.instance_eval do
            after_filter do
              Sunspot.commit_if_dirty
            end
          end
        end
      end
    end
  end
end
