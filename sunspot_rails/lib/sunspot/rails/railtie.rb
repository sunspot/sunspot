module Sunspot
  module Rails
    class Railtie < ::Rails::Railtie
      initializer 'sunspot_rails.init', :before=> :load_config_initializers do
        Sunspot.session = Sunspot::Rails.build_session
        ActiveSupport.on_load(:active_record) do
          Sunspot::Adapters::InstanceAdapter.register(Sunspot::Rails::Adapters::ActiveRecordInstanceAdapter, ActiveRecord::Base)
          Sunspot::Adapters::DataAccessor.register(Sunspot::Rails::Adapters::ActiveRecordDataAccessor, ActiveRecord::Base)
          include(Sunspot::Rails::Searchable)
        end
        ActiveSupport.on_load(:action_controller) do
          include(Sunspot::Rails::RequestLifecycle)
        end
        require 'sunspot/rails/log_subscriber'
        RSolr::Connection.module_eval{ include Sunspot::Rails::SolrInstrumentation }
      end

      # Expose database runtime to controller for logging.
      initializer "sunspot_rails.log_runtime" do |app|
        require "sunspot/rails/railties/controller_runtime"
        ActiveSupport.on_load(:action_controller) do
          include Sunspot::Rails::Railties::ControllerRuntime
        end
      end

      rake_tasks do
        load 'sunspot/rails/tasks.rb'
      end
      
      generators do
        load "generators/sunspot_rails.rb"
      end
      
      # When loading console, make it output to STDERR.
      console do
        Sunspot::Rails::LogSubscriber.logger = Logger.new(STDERR)
      end

    end
  end
end
