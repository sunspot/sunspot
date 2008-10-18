begin
  require 'spec'
  require 'ruby-debug'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  gem 'ruby-debug'
  require 'spec'
  require 'ruby-debug'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'sunspot'

Dir.glob(File.join(File.dirname(__FILE__), 'mocks', '**', '*.rb')).each { |file| require file }
