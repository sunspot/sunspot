desc 'Run spec suite in both Rails 2 and Rails 3'
task :spec => [:"spec:rails2", :"spec:rails3"]

namespace :spec do
  desc 'Run spec suite in Rails 2 application'
  task :rails2 do
    puts "Running specs for Rails 2"
    ENV['BUNDLE_GEMFILE'] = 'spec/rails2/Gemfile'
    ENV['RAILS_ROOT'] = 'spec/rails2'
    require 'bundler'
    Bundler.setup(:default, :test)
    # success = system "spec --color #{ENV['SPEC'] || 'spec'}"
    success = system "spec spec/*_spec.rb --color"
    exit(success ? 0 : 1)
  end

  desc 'Run spec suite in Rails 3 application'
  task :rails3 do
    puts "Running specs for Rails 3"
    ENV['BUNDLE_GEMFILE'] = 'spec/rails3/Gemfile'
    ENV['RAILS_ROOT'] = 'spec/rails3'
    require 'bundler'
    Bundler.setup(:default, :test)
    success = system "rspec #{ENV['SPEC'] || 'spec/*_spec.rb'} --color"
    exit(success ? 0 : 1)
  end
end
