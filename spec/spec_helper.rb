ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.join(File.dirname(__FILE__), 'mock_app')

require 'rubygems'
gem 'rspec'
require 'spec'

require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config', 'environment.rb'))

def load_schema
  config = YAML.load(IO.read(File.join(File.dirname(__FILE__), 'database.yml')))
  ActiveRecord::Base.establish_connection(config[db_adapter])
  load File.join(File.dirname(__FILE__), 'schema.rb')
end

Spec::Runner.configure do |config|
  config.before(:each) do
    load_schema
  end
end
