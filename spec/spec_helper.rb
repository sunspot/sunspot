require 'rubygems'
gem 'mislav-will_paginate', '~> 2.3'
gem 'rspec', '~> 1.1'
begin
  gem 'ruby-debug', '~>0.10'
  require 'ruby-debug'
rescue Gem::LoadError
  module Kernel
    def debugger
      raise("debugger is not available")
    end
  end
end
require 'spec'
require 'will_paginate'
require 'will_paginate/collection'

unless gem_name = ENV['SUNSPOT_TEST_GEM']
  $:.unshift(File.dirname(__FILE__) + '/../lib')
else
  gem gem_name
end
require 'sunspot'

require File.join(File.dirname(__FILE__), 'mocks', 'mock_record.rb')
Dir.glob(File.join(File.dirname(__FILE__), 'mocks', '**', '*.rb')).each { |file| require file }

def without_class(clazz)
  Object.class_eval { remove_const(clazz.name.to_sym) }
  yield
  Object.class_eval { const_set(clazz.name.to_sym, clazz) }
end
