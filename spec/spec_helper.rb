using_gems = false

if rsolr_gem_version = ENV['RSOLR_GEM_VERSION']
  STDERR.puts("Forcing RSolr gem version #{rsolr_gem_version}")
  using_gems = true
  require 'rubygems'
  gem 'rsolr', rsolr_gem_version
end

begin
  require 'spec'
  begin
    require 'ruby-debug'
  rescue LoadError => e
    if using_gems
      module Kernel
        def debugger
          STDERR.puts('Debugger is not available')
        end
      end
    else
      raise(e)
    end
  end
  if ENV['USE_WILL_PAGINATE']
    require 'will_paginate'
    require 'will_paginate/collection'
  end
rescue LoadError => e
  require 'rubygems'
  if using_gems
    raise(e)
  else
    using_gems = true
    retry
  end
end
require 'ostruct'

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
