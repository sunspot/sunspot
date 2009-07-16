using_gems = false
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

def without_class(clazz)
  Object.class_eval { remove_const(clazz.name.to_sym) }
  yield
  Object.class_eval { const_set(clazz.name.to_sym, clazz) }
end
