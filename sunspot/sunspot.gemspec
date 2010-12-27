# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)

$:.unshift(lib) unless $:.include?(lib)

require 'sunspot/version'

Gem::Specification.new do |s|
  s.name = 'sunspot'
  s.version = Sunspot::VERSION
  s.executables = ['sunspot-solr', 'sunspot-installer']
  s.email = 'mat@patch.com'
  s.homepage = 'http://outoftime.github.com/sunspot'
  s.summary = 'Library for expressive, powerful interaction with the Solr search engine'
  s.description = <<TEXT
Sunspot is a library providing a powerful, all-ruby API for the Solr search engine. Sunspot manages the configuration of persistent Ruby classes for search and indexing and exposes Solr's most powerful features through a collection of DSLs. Complex search operations can be performed without hand-writing any boolean queries or building Solr parameters by hand.
TEXT
  s.authors = ['Mat Brown', 'Peer Allan', 'Dmitriy Dzema', 'Benjamin Krause', 'Marcel de Graaf', 'Brandon Keepers', 'Peter Berkenbosch', 'Brian Atkinson', 'Tom Coleman', 'Matt Mitchell', 'Nathan Beyer', 'Kieran Topping', 'Nicolas Braem', 'Jeremy Ashkenas', 'Dylan Vaughn', 'Brian Durand', 'Sam Granieri', 'Nick Zadrozny', 'Jason Ronallo']
  s.rubyforge_project = 'sunspot'
  s.files = Dir.glob('[A-Z]*') +
            Dir.glob('{bin,installer,lib,spec,tasks,templates}/**/*') +
            Dir.glob('solr/{etc,lib,webapps}/**/*') +
            Dir.glob('solr/solr/{conf,lib}/*') << 'solr/start.jar'
  s.add_runtime_dependency 'rsolr', '0.12.1'
  s.add_runtime_dependency 'escape', '0.0.4'
  s.add_runtime_dependency 'pr_geohash', '~> 1.0'
  s.add_development_dependency 'rspec', '~> 1.1'
  s.extra_rdoc_files = [ 'README.rdoc' ] if File.exists?('README.rdoc')
  s.test_files = Dir.glob('spec/**/*_spec.rb')
  s.rdoc_options << '--webcvs=http://github.com/outoftime/sunspot/tree/master/%s' <<
                    '--title' << 'Sunspot - Solr-powered search for Ruby objects - API Documentation' <<
                    '--main' << 'README.rdoc'

end
