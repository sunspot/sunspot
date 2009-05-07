begin
  gem 'technicalpickles-jeweler', '~> 0.8.1'
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = 'sunspot'
    s.executables = 'sunspot-solr'
    s.summary = 'Library for expressive, powerful interaction with the Solr search engine'
    s.email = 'mat@patch.com'
    s.homepage = 'http://github.com/outoftime/sunspot'
    s.description = 'Library for expressive, powerful interaction with the Solr search engine'
    s.authors = ['Mat Brown']
    s.files = FileList['[A-Z]*', '{bin,lib,spec,tasks}/**/*', 'solr/{etc,lib,webapps}/**/*', 'solr/solr/conf/*', 'solr/start.jar']
    s.add_dependency 'solr-ruby', '>= 0.0.6'
    s.add_development_dependency 'rspec', '~> 1.1'
    s.add_development_dependency 'ruby-debug', '~> 0.10'
    s.extra_rdoc_files = ['README.rdoc']
    s.rdoc_options << '--webcvs=http://github.com/outoftime/sunspot/tree/master/%s' <<
                      '--title' << 'Sunspot - Pure-Ruby Solr Search and Indexing - API Documentation' <<
                      '--main' << 'README.rdoc'

  end
end
