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
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # Mock session available to all spec/api tests
  config.include MockSessionHelper, type: :api, file_path: /spec[\\\/]api/

  # Real Solr instance is available to integration tests
  config.include IntegrationHelper, type: :integration, file_path: /spec[\\\/]integration/

  # Nested under spec/api
  [:indexer, :query, :search].each do |spec_type|
    helper_name = "#{spec_type}_helper"

    config.include Sunspot::Util.full_const_get(Sunspot::Util.camel_case(helper_name)),
                   :type => spec_type,
                   :file_path => /spec[\\\/]api[\\\/]#{spec_type}/
  end
end

def without_class(clazz)
  Object.class_eval { remove_const(clazz.name.to_sym) }
  yield
  Object.class_eval { const_set(clazz.name.to_sym, clazz) }
end
