# -*- encoding: utf-8 -*-
lib = File.expand_path('../../sunspot/lib/', __FILE__)

$:.unshift(lib) unless $:.include?(lib)

require 'sunspot/version'

Gem::Specification.new do |s|
  s.name        = "sunspot_solr"
  s.version     = Sunspot::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Mat Brown', 'Peer Allan', 'Dmitriy Dzema', 'Benjamin Krause', 'Marcel de Graaf', 'Brandon Keepers', 'Peter Berkenbosch',
                  'Brian Atkinson', 'Tom Coleman', 'Matt Mitchell', 'Nathan Beyer', 'Kieran Topping', 'Nicolas Braem', 'Jeremy Ashkenas',
                  'Dylan Vaughn', 'Brian Durand', 'Sam Granieri', 'Nick Zadrozny', 'Jason Ronallo']
  s.email       = ["mat@patch.com"]
  s.homepage    = 'https://github.com/outoftime/sunspot/tree/master/sunspot_solr'
  s.summary     = 'Bundled Solr distribution for Sunspot'
  s.description = <<-TEXT
    Sunspot::Solr provides a bundled Solr distribution for use with Sunspot.
    Typical deployment environments will require more configuration, but this
    distribution is well suited to development and testing.
  TEXT

  s.rubyforge_project = "sunspot"

  s.files         = %w[
    Gemfile
    README.rdoc
    bin/sunspot-installer
    bin/sunspot-solr
    lib/sunspot/solr/installer.rb
    lib/sunspot/solr/installer/config_installer.rb
    lib/sunspot/solr/installer/task_helper.rb
    lib/sunspot/solr/java.rb
    lib/sunspot/solr/railtie.rb
    lib/sunspot/solr/server.rb
    lib/sunspot/solr/tasks.rb
    lib/sunspot_solr.rb
    solr/README.txt
    solr/etc/jetty.xml
    solr/etc/webdefault.xml
    solr/lib/jetty-6.1.3.jar
    solr/lib/jetty-util-6.1.3.jar
    solr/lib/jsp-2.1/ant-1.6.5.jar
    solr/lib/jsp-2.1/core-3.1.1.jar
    solr/lib/jsp-2.1/jsp-2.1.jar
    solr/lib/jsp-2.1/jsp-api-2.1.jar
    solr/lib/servlet-api-2.5-6.1.3.jar
    solr/solr/.gitignore
    solr/solr/README.txt
    solr/solr/conf/admin-extra.html
    solr/solr/conf/elevate.xml
    solr/solr/conf/mapping-ISOLatin1Accent.txt
    solr/solr/conf/protwords.txt
    solr/solr/conf/schema.xml
    solr/solr/conf/scripts.conf
    solr/solr/conf/solrconfig.xml
    solr/solr/conf/spellings.txt
    solr/solr/conf/stopwords.txt
    solr/solr/conf/synonyms.txt
    solr/solr/conf/xslt/example.xsl
    solr/solr/conf/xslt/example_atom.xsl
    solr/solr/conf/xslt/example_rss.xsl
    solr/solr/conf/xslt/luke.xsl
    solr/start.jar
    solr/webapps/solr.war
    spec/server_spec.rb
    spec/spec_helper.rb
  ]

  s.test_files    = %w[ spec/server_spec.rb spec/spec_helper.rb ]
  s.executables   = %w[ sunspot-installer sunspot-solr ]
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec', '~> 1.1'
  s.add_development_dependency 'hanna'

  s.rdoc_options << '--webcvs=http://github.com/outoftime/sunspot/tree/master/%s' <<
                  '--title' << 'Sunspot-Solr - Bundled Solr distribution for Sunspot - API Documentation' <<
                  '--main' << 'README.rdoc'
end
