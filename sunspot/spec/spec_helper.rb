# encoding: utf-8

require 'ostruct'
require 'sunspot'

require File.join(File.dirname(__FILE__), 'mocks', 'mock_record.rb')
Dir.glob(File.join(File.dirname(__FILE__), 'mocks', '**', '*.rb')).each do |file|
  require file unless File.basename(file) == 'mock_record.rb'
end
Dir.glob(File.join(File.dirname(__FILE__), "helpers", "*.rb")).each do |file|
  require file
end
require File.join(File.dirname(__FILE__), 'ext')

RSpec.configure do |config|
  config.before(:each, :type => :integration) do
    Sunspot.config.solr.url = ENV['SOLR_URL'] || 'http://localhost:8983/solr'
  end

  # Mock session available to all spec/api tests
  config.include MockSessionHelper,
                 :type => :api,
                 :example_group => {:file_path => /spec[\\\/]api/}

  # Nested under spec/api
  [:indexer, :query, :search].each do |spec_type|
    helper_name = "#{spec_type}_helper"

    config.include Sunspot::Util.full_const_get(Sunspot::Util.camel_case(helper_name)),
                   :type          => spec_type,
                   :example_group => {:file_path => /spec[\\\/]api[\\\/]#{spec_type}/}
  end
end

def without_class(clazz)
  Object.class_eval { remove_const(clazz.name.to_sym) }
  yield
  Object.class_eval { const_set(clazz.name.to_sym, clazz) }
end
