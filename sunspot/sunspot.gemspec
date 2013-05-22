# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)
require "sunspot/version"

Gem::Specification.new do |s|
  s.name        = "sunspot"
  s.version     = Sunspot::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Mat Brown', 'Peer Allan', 'Dmitriy Dzema', 'Benjamin Krause', 'Marcel de Graaf', 'Brandon Keepers', 'Peter Berkenbosch',
                  'Brian Atkinson', 'Tom Coleman', 'Matt Mitchell', 'Nathan Beyer', 'Kieran Topping', 'Nicolas Braem', 'Jeremy Ashkenas',
                  'Dylan Vaughn', 'Brian Durand', 'Sam Granieri', 'Nick Zadrozny', 'Jason Ronallo']
  s.email       = ["mat@patch.com"]
  s.homepage    = "http://outoftime.github.com/sunspot"
  s.summary = 'Library for expressive, powerful interaction with the Solr search engine'
  s.license = 'MIT'
  s.description = <<-TEXT
    Sunspot is a library providing a powerful, all-ruby API for the Solr search engine. Sunspot manages the configuration of persistent
    Ruby classes for search and indexing and exposes Solr's most powerful features through a collection of DSLs. Complex search operations
    can be performed without hand-writing any boolean queries or building Solr parameters by hand.
  TEXT

  s.rubyforge_project = "sunspot"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'rsolr', '~>1.0.7'
  s.add_dependency 'pr_geohash', '~>1.0'

  s.add_development_dependency 'rspec', '~>2.6.0'
  s.add_development_dependency 'hanna'

  s.rdoc_options << '--webcvs=http://github.com/outoftime/sunspot/tree/master/%s' <<
                  '--title' << 'Sunspot - Solr-powered search for Ruby objects - API Documentation' <<
                  '--main' << 'README.rdoc'
end
