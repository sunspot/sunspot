ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.join(File.dirname(__FILE__), 'mock_app')
if rsolr_version = ENV['RSOLR_GEM_VERSION']
  STDERR.puts("Forcing RSolr version #{rsolr_version}")
  gem "rsolr", rsolr_version
end

if File.exist?(sunspot_lib = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'sunspot', 'lib')))
  STDERR.puts("Using sunspot lib at #{sunspot_lib}")
  $: << sunspot_lib
end

require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config', 'environment.rb'))

require 'spec'
require 'spec/rails'
require 'rake'
require 'ruby-debug' unless RUBY_VERSION > '1.9'
require File.join(File.dirname(__FILE__), '..', 'lib', 'sunspot', 'rails', 'solr_logging')

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
    load_schema
    Sunspot.remove_all!
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
