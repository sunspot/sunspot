begin
  require 'matchy'
  require 'context'
  require 'rr'
  require 'ruby-debug'
  gem 'mislav-will_paginate', '>= 2.3'
  require 'will_paginate'
  require 'will_paginate/collection'
rescue LoadError
  require 'rubygems'
  require 'matchy'
  require 'context'
  require 'rr'
  require 'ruby-debug'
  gem 'mislav-will_paginate', '>= 2.3'
  require 'will_paginate'
  require 'will_paginate/collection'
end

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
