ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.join(File.dirname(__FILE__), 'mock_app')

if File.exist?(sunspot_lib = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'sunspot', 'lib')))
  STDERR.puts("Using sunspot lib at #{sunspot_lib}")
  $: << sunspot_lib
end

require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config', 'environment.rb'))

require 'spec'
require 'spec/rails'
require 'rake'
require 'ruby-debug' unless RUBY_VERSION > '1.9'
require 'sunspot/rails/tasks'
require 'sunspot/spec/extension'

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

Spec::Runner.configure do |config|
  config.before(:each) do
    if integrate_sunspot?
      Sunspot.remove_all
      Sunspot.commit
    end
    load_schema
  end
end

module Spec
  module Mocks
    module Methods
      def should_respond_to_and_receive(*args, &block)
        respond_to?(args.first).should ==(true)
        should_receive(*args, &block)
      end
    end
  end
end
