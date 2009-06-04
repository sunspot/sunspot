require 'sunspot'

Sunspot.config.solr.url = URI::HTTP.build(:host => Sunspot::Rails.configuration.hostname,
                                          :port => Sunspot::Rails.configuration.port,
                                          :path => Sunspot::Rails.configuration.path).to_s

Sunspot::Adapters::InstanceAdapter.register(Sunspot::Rails::Adapters::ActiveRecordInstanceAdapter, ActiveRecord::Base)
Sunspot::Adapters::DataAccessor.register(Sunspot::Rails::Adapters::ActiveRecordDataAccessor, ActiveRecord::Base)
ActiveRecord::Base.module_eval { include(Sunspot::Rails::Searchable) }
ActionController::Base.module_eval { include(Sunspot::Rails::RequestLifecycle) }
