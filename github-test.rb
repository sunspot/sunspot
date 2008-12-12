#!/usr/bin/env ruby
require 'yaml'

if ARGV.size < 1
  puts "Usage: github-test.rb my-project.gemspec"
  exit
end

require 'rubygems/specification'
data = File.read(ARGV[0])
spec = nil

if data !~ %r{!ruby/object:Gem::Specification}
  Thread.new { spec = eval("$SAFE = 3\n#{data}") }.join
else
  spec = YAML.load(data)
end

spec.validate

puts spec
puts "OK"
