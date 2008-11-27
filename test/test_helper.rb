require 'rubygems'
gem 'jeremymcanally-matchy', '>= 0.0.1'
gem 'jeremymcanally-context', '=0.0.3' # for some reason, in 0.0.6, stubs done in setup blocks don't stick
gem 'rr', '~> 0.6'
gem 'ruby-debug', '~>0.10'
gem 'mislav-will_paginate', '~> 2.3'

require 'matchy'
require 'context'
require 'ruby-debug'
require 'will_paginate'
require 'will_paginate/collection'
require 'mocha'

require File.join(File.dirname(__FILE__), 'custom_expectation')

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'sunspot'

Dir.glob(File.join(File.dirname(__FILE__), 'mocks', '**', '*.rb')).each { |file| require file }

class Test::Unit::TestCase
  def without_class(clazz)
    Object.class_eval { remove_const(clazz.name.to_sym) }
    yield
    Object.class_eval { const_set(clazz.name.to_sym, clazz) }
  end
end
