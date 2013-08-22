ENV['RAILS_ENV'] = 'test'
if rsolr_version = ENV['RSOLR_GEM_VERSION']
  STDERR.puts("Forcing RSolr version #{rsolr_version}")
  gem "rsolr", rsolr_version
end

require File.expand_path('config/environment', ENV['RAILS_ROOT'])

require 'rspec/rails'
require 'rake'
require File.join('sunspot', 'rails', 'solr_logging')

def load_schema
  stdout = $stdout
  $stdout = StringIO.new # suppress output while building the schema
  load File.join(ENV['RAILS_ROOT'], 'db', 'schema.rb')
  $stdout = stdout
end

def silence_stderr(&block)
  stderr = $stderr
  $stderr = StringIO.new
  yield
  $stderr = stderr
end

# Load all shared examples
Dir[File.expand_path("shared_examples/*.rb", File.dirname(__FILE__))].each {|f| require f}

RSpec.configure do |config|
  config.before(:each) do
    load_schema
    Sunspot.remove_all!
  end
end
