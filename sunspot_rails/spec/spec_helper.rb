ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.join(File.dirname(__FILE__), 'rails3')
if rsolr_version = ENV['RSOLR_GEM_VERSION']
  STDERR.puts("Forcing RSolr version #{rsolr_version}")
  gem "rsolr", rsolr_version
end

require File.expand_path('config/environment', ENV['RAILS_ROOT'])

begin
  require 'rspec'
  require 'rspec/rails'
rescue LoadError => e
  require 'spec'
  require 'spec/rails'
end
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

rspec = 
  begin
    RSpec
  rescue NameError
    Spec::Runner
  end

rspec.configure do |config|
  config.before(:each) do
    load_schema
    Sunspot.remove_all!
  end
end
