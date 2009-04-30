ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.join(File.dirname(__FILE__), 'mock_app')

require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config', 'environment.rb'))

require 'spec'
require 'ruby-debug'

def load_schema
#   config = YAML.load(IO.read(File.join(File.dirname(__FILE__), 'database.yml')))
#   ActiveRecord::Base.establish_connection(config[db_adapter])
  stdout = $stdout
  $stdout = StringIO.new
  load File.join(File.dirname(__FILE__), 'schema.rb')
  $stdout = stdout
end

Spec::Runner.configure do |config|
  config.before(:each) do
    Sunspot.remove_all
    Sunspot.commit
    load_schema
  end
end
