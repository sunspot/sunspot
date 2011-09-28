# encoding: UTF-8

require 'rspec/core/rake_task'

Dir['tasks/**/*.rake'].each { |t| load t }

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--format documentation'
  t.ruby_opts  = "-W1"
end

task :default => :spec
