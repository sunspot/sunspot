begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = 'sunspot'
    s.executables = ['sunspot-solr', 'sunspot-configure-solr']
    s.summary = 'Library for expressive, powerful interaction with the Solr search engine'
    s.email = 'mat@patch.com'
    s.homepage = 'http://github.com/outoftime/sunspot'
    s.description = 'Library for expressive, powerful interaction with the Solr search engine'
    s.authors = ['Mat Brown', 'Peer Allan', 'Dmitriy Dzema', 'Benjamin Krause']
    s.files = FileList['[A-Z]*', '{bin,lib,spec,tasks,templates}/**/*', 'solr/{etc,lib,webapps}/**/*', 'solr/solr/conf/*', 'solr/start.jar']
    s.add_dependency 'mwmitchell-rsolr', '= 0.9.6'
    s.add_dependency 'daemons', '~> 1.0'
    s.add_dependency 'optiflag', '~> 0.6.5'
    s.add_dependency 'haml', '~> 2.2'
    s.add_development_dependency 'rspec', '~> 1.1'
    s.add_development_dependency 'ruby-debug', '~> 0.10'
    s.extra_rdoc_files = ['README.rdoc']
    s.rdoc_options << '--webcvs=http://github.com/outoftime/sunspot/tree/master/%s' <<
                      '--title' << 'Sunspot - Solr-powered search for Ruby objects - API Documentation' <<
                      '--main' << 'README.rdoc'

  end
end
