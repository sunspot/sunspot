require 'rubygems'
gem 'ruby-debug', '~>0.10'
gem 'mislav-will_paginate', '~> 2.3'
gem 'rspec', '~> 1.1'

require 'ruby-debug'
require 'spec'
require 'will_paginate'
require 'will_paginate/collection'

unless gem_name = ENV['SUNSPOT_TEST_GEM']
  $:.unshift(File.dirname(__FILE__) + '/../lib')
else
  gem gem_name
end
require 'sunspot'

require File.join(File.dirname(__FILE__), 'mocks', 'base_class.rb')
Dir.glob(File.join(File.dirname(__FILE__), 'mocks', '**', '*.rb')).each { |file| require file }

def without_class(clazz)
  Object.class_eval { remove_const(clazz.name.to_sym) }
  yield
  Object.class_eval { const_set(clazz.name.to_sym, clazz) }
end
