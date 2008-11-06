begin
  require 'matchy'
  require 'context'
  require 'mocha'
  require 'ruby-debug'
rescue LoadError
  require 'rubygems'
  gem 'ruby-debug'
  gem 'matchy'
  gem 'jeremymcanally-context'
  gem 'mocha'
  require 'matchy'
  require 'context'
  require 'mocha'
  require 'ruby-debug'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'sunspot'

Dir.glob(File.join(File.dirname(__FILE__), 'mocks', '**', '*.rb')).each { |file| require file }
