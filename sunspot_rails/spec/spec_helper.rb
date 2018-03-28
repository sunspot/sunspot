ENV["RAILS_ENV"] ||= 'test'

require File.expand_path('config/environment', File.expand_path('../rails_app', __FILE__))
require File.expand_path('../../lib/sunspot_rails', __FILE__)
require 'rspec/rails'

if RSolr::VERSION >= '2'
  require File.join('sunspot', 'rails', 'solr_logging')
end

# Load all shared examples
Dir[File.expand_path("shared_examples/*.rb", File.dirname(__FILE__))].each { |f| require f }

# Load the schema
load File.join(File.expand_path('../rails_app', __FILE__), 'db', 'schema.rb')

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = 'random'
  config.infer_spec_type_from_file_location!

  config.before(:each) do
    empty_tables
    Sunspot.remove_all!
  end
end

def empty_tables
  sources = if Rails::VERSION::MAJOR > 4
              ActiveRecord::Base.connection.data_sources
            else
              ActiveRecord::Base.connection.tables
            end
  sources.each do |table_name|
    ActiveRecord::Base.connection.execute("DELETE FROM #{table_name}") unless table_name == 'schema_migrations'
  end
end

def relation(clazz)
  Rails::VERSION::MAJOR >= 4 ? clazz.all : clazz.scoped
end
