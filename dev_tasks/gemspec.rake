begin
  gem 'technicalpickles-jeweler', '~> 1.0'
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = 'sunspot_rails'
    s.summary = 'Rails integration for the Sunspot Solr search library'
    s.email = 'mat@patch.com'
    s.homepage = 'http://github.com/outoftime/sunspot_rails'
    s.description = 'Rails integration for the Sunspot Solr search library'
    s.authors = ['Mat Brown', 'Peer Allan', 'Michael Moen', 'Benjamin Krause', 'Adam Salter', 'Brandon Keepers']
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
    s.add_dependency 'rails', '~> 2.1'
    s.add_dependency 'escape', '>= 0.0.4'
    s.add_dependency 'outoftime-sunspot', '>= 0.8.2'
    s.add_development_dependency 'rspec', '~> 1.2'
    s.add_development_dependency 'rspec-rails', '~> 1.2'
    s.add_development_dependency 'ruby-debug', '~> 0.10'
    s.add_development_dependency 'technicalpickles-jeweler', '~> 1.0'
  end
end
