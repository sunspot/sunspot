require 'sunspot'

Sunspot.config.solr.url = URI::HTTP.build(:host => Sunspot::Rails.configuration.hostname,
                                          :port => Sunspot::Rails.configuration.port,
                                          :path => Sunspot::Rails.configuration.path).to_s

if Sunspot::Rails.configuration.master?
  Sunspot.config.master_solr.url = URI::HTTP.build(:host => Sunspot::Rails.configuration.master_hostname,
                                            :port => Sunspot::Rails.configuration.master_port,
                                            :path => Sunspot::Rails.configuration.master_path).to_s
end

Sunspot::Adapters::InstanceAdapter.register(Sunspot::Rails::Adapters::ActiveRecordInstanceAdapter, ActiveRecord::Base)
Sunspot::Adapters::DataAccessor.register(Sunspot::Rails::Adapters::ActiveRecordDataAccessor, ActiveRecord::Base)
ActiveRecord::Base.module_eval { include(Sunspot::Rails::Searchable) }
ActionController::Base.module_eval { include(Sunspot::Rails::RequestLifecycle) }
