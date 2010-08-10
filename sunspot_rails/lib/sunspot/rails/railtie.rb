module Sunspot
  module Rails
    class Railtie < ::Rails::Railtie
      initializer 'sunspot_rails.init' do
        Sunspot.session = Sunspot::Rails.build_session
        Sunspot::Adapters::InstanceAdapter.register(Sunspot::Rails::Adapters::ActiveRecordInstanceAdapter, ActiveRecord::Base)
        Sunspot::Adapters::DataAccessor.register(Sunspot::Rails::Adapters::ActiveRecordDataAccessor, ActiveRecord::Base)
        ActiveSupport.on_load(:active_record) do
          include(Sunspot::Rails::Searchable)
        end
        ActiveSupport.on_load(:action_controller) do
          include(Sunspot::Rails::RequestLifecycle)
        end
      end

      rake_tasks do
        load 'sunspot/rails/tasks'
      end
      
      generators do
        load "generators/sunspot_rails.rb"
      end

    end
  end
end
