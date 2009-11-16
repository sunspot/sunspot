begin
  gem 'technicalpickles-jeweler', '~> 1.0'
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = 'sunspot_rails'
    s.summary = 'Rails integration for the Sunspot Solr search library'
    s.email = 'mat@patch.com'
    s.homepage = 'http://github.com/outoftime/sunspot_rails'
    s.description = <<TEXT
Sunspot::Rails is an extension to the Sunspot library for Solr search.
Sunspot::Rails adds integration between Sunspot and ActiveRecord, including
defining search and indexing related methods on ActiveRecord models themselves,
running a Sunspot-compatible Solr instance for development and test
environments, and automatically commit Solr index changes at the end of each
Rails request.
TEXT
    s.authors = ['Mat Brown', 'Peer Allan', 'Michael Moen', 'Benjamin Krause']
    s.rubyforge_project = 'sunspot'
    s.files = FileList['[A-Z]*',
                       '{lib,tasks,dev_tasks}/**/*',
                       'generators/**/*',
                       'install.rb',
                       'MIT-LICENSE',
                       'rails/*',
                       'spec/*.rb',
                       'spec/mock_app/{app,lib,db,vendor,config}/**/*',
                       'spec/mock_app/{tmp,log,solr}']
    s.add_dependency 'escape', '>= 0.0.4'
    s.add_dependency 'sunspot', '>= 0.10.6', '<= 0.10.7'
    s.add_development_dependency 'rspec', '~> 1.2'
    s.add_development_dependency 'rspec-rails', '~> 1.2'
    s.add_development_dependency 'ruby-debug', '~> 0.10'
    s.add_development_dependency 'technicalpickles-jeweler', '~> 1.0'
  end

  Jeweler::RubyforgeTasks.new
  Jeweler::GemcutterTasks.new
end

namespace :release do
  task :tag do
    version = Jeweler::VersionHelper.new(File.join(File.dirname(__FILE__), '..')).to_s
    `git tag -a -m "Version #{version}" v#{version}`
    `git push origin v#{version}:v#{version}`
  end

  task :commit_gemspec do
    version = Jeweler::VersionHelper.new(File.join(File.dirname(__FILE__), '..')).to_s
    `git add sunspot_rails.gemspec`
    `git commit -m "Generate gemspec for v#{version}"`
  end

  desc "Release gem to RubyForge and GitHub"
  task :all => [:gemspec, :commit_gemspec, :tag, :"rubyforge:release:gem", :"gemcutter:release"]
end
