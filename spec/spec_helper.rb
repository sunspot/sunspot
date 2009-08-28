ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.join(File.dirname(__FILE__), 'mock_app')

require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config', 'environment.rb'))

require 'spec'
require 'spec/rails'
require 'rake'
require 'ruby-debug'
require 'sunspot/rails/tasks'

def load_schema
  stdout = $stdout
  $stdout = StringIO.new # suppress output while building the schema
  load File.join(File.dirname(__FILE__), 'schema.rb')
  $stdout = stdout
end

def silence_stderr(&block)
  stderr = $stderr
  $stderr = StringIO.new
  yield
  $stderr = stderr
end

Spec::Runner.configure do |config|
  config.before(:suite) do
    Rake::Task['sunspot:solr:start'].execute
  end
  
  config.before(:each) do
    Sunspot.remove_all
    Sunspot.commit
    load_schema
  end
end
