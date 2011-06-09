module Sunspot
  module Rails
    module Railties
      module ControllerRuntime
        extend ActiveSupport::Concern

        protected

        attr_internal :solr_runtime

        def cleanup_view_runtime
          # TODO only if solr is connected? if not call to super

          solr_rt_before_render = Sunspot::Rails::LogSubscriber.reset_runtime
          runtime = super
          solr_rt_after_render = Sunspot::Rails::LogSubscriber.reset_runtime
          self.solr_runtime = solr_rt_before_render + solr_rt_after_render
          runtime - solr_rt_after_render
        end

        def append_info_to_payload(payload)
          super
          payload[:solr_runtime] = solr_runtime
        end

        module ClassMethods
          def log_process_action(payload)
            messages, solr_runtime = super, payload[:solr_runtime]
            messages << ("Solr: %.1fms" % solr_runtime.to_f) if solr_runtime
            messages
          end
        end
      end
    end
  end
end