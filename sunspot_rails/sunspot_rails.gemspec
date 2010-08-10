# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)

$:.unshift(lib) unless $:.include?(lib)

require 'sunspot/rails/version'

Gem::Specification.new do |s|
  s.name = 'sunspot_rails'
  s.version = Sunspot::Rails::VERSION
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
  s.authors = ['Mat Brown', 'Peer Allan', 'Michael Moen', 'Benjamin Krause', 'Adam Salter', 'Brandon Keepers', 'Paul Canavese', 'John Eberly', 'Gert Thiel']
  s.rubyforge_project = 'sunspot'
  s.files =
    Dir.glob('[A-Z]*') +
    Dir.glob('{lib,tasks,dev_tasks}/**/*') +
    Dir.glob('generators/**/*') +
    ['install.rb', 'MIT-LICENSE'] +
    Dir.glob('spec/*.rb') +
    Dir.glob('spec/mock_app/{app,lib,db,vendor,config}/**/*') +
    Dir.glob('spec/mock_app/{tmp,log,solr}')
  s.add_dependency 'sunspot', Sunspot::Rails::VERSION
  s.add_development_dependency 'rspec', '~> 1.2'
  s.add_development_dependency 'rspec-rails', '~> 1.2'
end
