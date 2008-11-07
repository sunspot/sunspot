begin
  require 'matchy'
  require 'context'
  require 'rr'
  require 'ruby-debug'
rescue LoadError
  require 'rubygems'
  require 'matchy'
  require 'context'
  require 'rr'
  require 'ruby-debug'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'sunspot'

Dir.glob(File.join(File.dirname(__FILE__), 'mocks', '**', '*.rb')).each { |file| require file }

Test::Unit::TestCase.class_eval { include RR::Adapters::TestUnit }
