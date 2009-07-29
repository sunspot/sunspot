# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{sunspot}
  s.version = "0.9.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mat Brown", "Peer Allan", "Dmitriy Dzema", "Benjamin Krause"]
  s.date = %q{2009-07-29}
  s.description = %q{Library for expressive, powerful interaction with the Solr search engine}
  s.email = %q{mat@patch.com}
  s.executables = ["sunspot-solr", "sunspot-configure-solr"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "History.txt",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "TODO",
     "VERSION.yml",
     "bin/sunspot-configure-solr",
     "bin/sunspot-solr",
     "lib/light_config.rb",
     "lib/sunspot.rb",
     "lib/sunspot/adapters.rb",
     "lib/sunspot/composite_setup.rb",
     "lib/sunspot/configuration.rb",
     "lib/sunspot/data_extractor.rb",
     "lib/sunspot/date_facet.rb",
     "lib/sunspot/date_facet_row.rb",
     "lib/sunspot/dsl.rb",
     "lib/sunspot/dsl/field_query.rb",
     "lib/sunspot/dsl/fields.rb",
     "lib/sunspot/dsl/query.rb",
     "lib/sunspot/dsl/query_facet.rb",
     "lib/sunspot/dsl/restriction.rb",
     "lib/sunspot/dsl/scope.rb",
     "lib/sunspot/dsl/search.rb",
     "lib/sunspot/facet.rb",
     "lib/sunspot/facet_row.rb",
     "lib/sunspot/field.rb",
     "lib/sunspot/field_factory.rb",
     "lib/sunspot/indexer.rb",
     "lib/sunspot/instantiated_facet.rb",
     "lib/sunspot/instantiated_facet_row.rb",
     "lib/sunspot/query.rb",
     "lib/sunspot/query/base_query.rb",
     "lib/sunspot/query/connective.rb",
     "lib/sunspot/query/dynamic_query.rb",
     "lib/sunspot/query/field_facet.rb",
     "lib/sunspot/query/field_query.rb",
     "lib/sunspot/query/pagination.rb",
     "lib/sunspot/query/query_facet.rb",
     "lib/sunspot/query/query_facet_row.rb",
     "lib/sunspot/query/restriction.rb",
     "lib/sunspot/query/scope.rb",
     "lib/sunspot/query/sort.rb",
     "lib/sunspot/query/sort_composite.rb",
     "lib/sunspot/query_facet.rb",
     "lib/sunspot/query_facet_row.rb",
     "lib/sunspot/schema.rb",
     "lib/sunspot/search.rb",
     "lib/sunspot/search/hit.rb",
     "lib/sunspot/session.rb",
     "lib/sunspot/setup.rb",
     "lib/sunspot/type.rb",
     "lib/sunspot/util.rb",
     "solr/etc/jetty.xml",
     "solr/etc/webdefault.xml",
     "solr/lib/jetty-6.1.3.jar",
     "solr/lib/jetty-util-6.1.3.jar",
     "solr/lib/jsp-2.1/ant-1.6.5.jar",
     "solr/lib/jsp-2.1/core-3.1.1.jar",
     "solr/lib/jsp-2.1/jsp-2.1.jar",
     "solr/lib/jsp-2.1/jsp-api-2.1.jar",
     "solr/lib/servlet-api-2.5-6.1.3.jar",
     "solr/solr/conf/elevate.xml",
     "solr/solr/conf/protwords.txt",
     "solr/solr/conf/schema.xml",
     "solr/solr/conf/solrconfig.xml",
     "solr/solr/conf/stopwords.txt",
     "solr/solr/conf/synonyms.txt",
     "solr/start.jar",
     "solr/webapps/solr.war",
     "spec/api/adapters_spec.rb",
     "spec/api/build_search_spec.rb",
     "spec/api/indexer_spec.rb",
     "spec/api/query_spec.rb",
     "spec/api/search_retrieval_spec.rb",
     "spec/api/session_spec.rb",
     "spec/api/spec_helper.rb",
     "spec/api/sunspot_spec.rb",
     "spec/integration/dynamic_fields_spec.rb",
     "spec/integration/faceting_spec.rb",
     "spec/integration/keyword_search_spec.rb",
     "spec/integration/scoped_search_spec.rb",
     "spec/integration/spec_helper.rb",
     "spec/integration/stored_fields_spec.rb",
     "spec/integration/test_pagination.rb",
     "spec/mocks/adapters.rb",
     "spec/mocks/blog.rb",
     "spec/mocks/comment.rb",
     "spec/mocks/connection.rb",
     "spec/mocks/mock_adapter.rb",
     "spec/mocks/mock_record.rb",
     "spec/mocks/photo.rb",
     "spec/mocks/post.rb",
     "spec/mocks/user.rb",
     "spec/spec_helper.rb",
     "tasks/gemspec.rake",
     "tasks/rcov.rake",
     "tasks/rdoc.rake",
     "tasks/schema.rake",
     "tasks/spec.rake",
     "tasks/todo.rake",
     "templates/schema.xml.haml"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/outoftime/sunspot}
  s.rdoc_options = ["--charset=UTF-8", "--webcvs=http://github.com/outoftime/sunspot/tree/master/%s", "--title", "Sunspot - Solr-powered search for Ruby objects - API Documentation", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{Library for expressive, powerful interaction with the Solr search engine}
  s.test_files = [
    "spec/spec_helper.rb",
     "spec/integration/spec_helper.rb",
     "spec/integration/faceting_spec.rb",
     "spec/integration/scoped_search_spec.rb",
     "spec/integration/keyword_search_spec.rb",
     "spec/integration/dynamic_fields_spec.rb",
     "spec/integration/stored_fields_spec.rb",
     "spec/integration/test_pagination.rb",
     "spec/mocks/mock_record.rb",
     "spec/mocks/blog.rb",
     "spec/mocks/adapters.rb",
     "spec/mocks/mock_adapter.rb",
     "spec/mocks/user.rb",
     "spec/mocks/photo.rb",
     "spec/mocks/post.rb",
     "spec/mocks/comment.rb",
     "spec/mocks/connection.rb",
     "spec/api/search_retrieval_spec.rb",
     "spec/api/spec_helper.rb",
     "spec/api/session_spec.rb",
     "spec/api/adapters_spec.rb",
     "spec/api/build_search_spec.rb",
     "spec/api/sunspot_spec.rb",
     "spec/api/indexer_spec.rb",
     "spec/api/query_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mwmitchell-rsolr>, [">= 0.8.9"])
      s.add_runtime_dependency(%q<daemons>, ["~> 1.0"])
      s.add_runtime_dependency(%q<optiflag>, ["~> 0.6.5"])
      s.add_runtime_dependency(%q<haml>, ["~> 2.2"])
      s.add_development_dependency(%q<rspec>, ["~> 1.1"])
      s.add_development_dependency(%q<ruby-debug>, ["~> 0.10"])
    else
      s.add_dependency(%q<mwmitchell-rsolr>, [">= 0.8.9"])
      s.add_dependency(%q<daemons>, ["~> 1.0"])
      s.add_dependency(%q<optiflag>, ["~> 0.6.5"])
      s.add_dependency(%q<haml>, ["~> 2.2"])
      s.add_dependency(%q<rspec>, ["~> 1.1"])
      s.add_dependency(%q<ruby-debug>, ["~> 0.10"])
    end
  else
    s.add_dependency(%q<mwmitchell-rsolr>, [">= 0.8.9"])
    s.add_dependency(%q<daemons>, ["~> 1.0"])
    s.add_dependency(%q<optiflag>, ["~> 0.6.5"])
    s.add_dependency(%q<haml>, ["~> 2.2"])
    s.add_dependency(%q<rspec>, ["~> 1.1"])
    s.add_dependency(%q<ruby-debug>, ["~> 0.10"])
  end
end
