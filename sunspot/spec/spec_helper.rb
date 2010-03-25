if rsolr_gem_version = ENV['RSOLR_GEM_VERSION']
  STDERR.puts("Forcing rsolr gem version #{rsolr_gem_version}")
  using_gems = true
  require 'rubygems'
  gem 'rsolr', rsolr_gem_version
end

require 'ostruct'
begin
  require 'spec'
  if ENV['USE_WILL_PAGINATE']
    require 'will_paginate'
    require 'will_paginate/collection'
  end
rescue LoadError => e
  if require 'rubygems'
    retry
  else
    raise(e)
  end
end

unless gem_name = ENV['SUNSPOT_TEST_GEM']
  $:.unshift(File.dirname(__FILE__) + '/../lib')
else
  gem gem_name
end
require 'sunspot'

require File.join(File.dirname(__FILE__), 'mocks', 'mock_record.rb')
Dir.glob(File.join(File.dirname(__FILE__), 'mocks', '**', '*.rb')).each do |file|
  require file unless File.basename(file) == 'mock_record.rb'
end
require File.join(File.dirname(__FILE__), 'ext')

Spec::Runner.configure do |config|
  Dir.glob(File.join(File.dirname(__FILE__), 'helpers', '*_helper.rb')).each do |helper|
    helper_name = File.basename(helper, File.extname(helper))
    spec_type = helper_name.sub(/_helper$/, '').to_sym
    require(helper)
    config.include(
      Sunspot::Util.full_const_get(Sunspot::Util.camel_case(helper_name)),
      :type => spec_type
    )
  end
end

def without_class(clazz)
  Object.class_eval { remove_const(clazz.name.to_sym) }
  yield
  Object.class_eval { const_set(clazz.name.to_sym, clazz) }
end
