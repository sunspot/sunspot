require File.expand_path('spec_helper', File.join(File.dirname(__FILE__), '..'))

Dir.glob(File.join(File.dirname(__FILE__), '**', '*_examples.rb')).each { |shared| require(shared) }
