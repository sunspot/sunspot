require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

Dir.glob(File.join(File.dirname(__FILE__), '**', '*_examples.rb')).each { |shared| require(shared) }
