# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
if rsolr_version = ENV['RSOLR_GEM_VERSION']
  STDERR.puts("Forcing RSolr version #{rsolr_version}")
  gem "rsolr", rsolr_version
end

# Require the Database-specific gems
ENV['DB'] ||= 'sqlite'
Bundler.require(ENV['DB'])

require File.expand_path('config/environment', ENV['RAILS_ROOT'])
require 'rspec/rails'
require 'rspec/autorun'
require File.join('sunspot', 'rails', 'solr_logging')

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Load all shared examples
Dir[File.expand_path("shared_examples/*.rb", File.dirname(__FILE__))].each {|f| require f}

# Load the schema
load File.join(ENV['RAILS_ROOT'], 'db', 'schema.rb')

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  # --seed 1234
  config.order = "random"

  config.before(:each) do
    empty_tables
    Sunspot.remove_all!
  end  
end

def empty_tables
  ActiveRecord::Base.connection.tables.each do |table_name|
    ActiveRecord::Base.connection.execute("DELETE FROM #{table_name}") unless table_name == 'schema_migrations'
  end
end

# COMPATIBILITY: Rails 4 has deprecated the 'scoped' method in favour of 'all'
def relation(clazz)
  ::Rails.version >= '4' ? clazz.all : clazz.scoped
end