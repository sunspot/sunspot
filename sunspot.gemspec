# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{sunspot}
  s.version = "0.8.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mat Brown"]
  s.date = %q{2009-05-27}
  s.default_executable = %q{sunspot-solr}
  s.description = %q{Library for expressive, powerful interaction with the Solr search engine}
  s.email = %q{mat@patch.com}
  s.executables = ["sunspot-solr"]
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
     "bin/sunspot-solr",
     "lib/light_config.rb",
     "lib/sunspot.rb",
     "lib/sunspot/adapters.rb",
     "lib/sunspot/configuration.rb",
     "lib/sunspot/data_extractor.rb",
     "lib/sunspot/dsl.rb",
     "lib/sunspot/dsl/fields.rb",
     "lib/sunspot/dsl/query.rb",
     "lib/sunspot/dsl/restriction.rb",
     "lib/sunspot/dsl/scope.rb",
     "lib/sunspot/facet.rb",
     "lib/sunspot/facet_row.rb",
     "lib/sunspot/field.rb",
     "lib/sunspot/indexer.rb",
     "lib/sunspot/query.rb",
     "lib/sunspot/query/dynamic_query.rb",
     "lib/sunspot/query/field_facet.rb",
     "lib/sunspot/query/pagination.rb",
     "lib/sunspot/query/restriction.rb",
     "lib/sunspot/query/sort.rb",
     "lib/sunspot/search.rb",
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
     "spec/api/build_search_spec.rb",
     "spec/api/indexer_spec.rb",
     "spec/api/query_spec.rb",
     "spec/api/search_retrieval_spec.rb",
     "spec/api/session_spec.rb",
     "spec/api/spec_helper.rb",
     "spec/integration/dynamic_fields_spec.rb",
     "spec/integration/faceting_spec.rb",
     "spec/integration/keyword_search_spec.rb",
     "spec/integration/scoped_search_spec.rb",
     "spec/integration/spec_helper.rb",
     "spec/integration/test_pagination.rb",
     "spec/mocks/base_class.rb",
     "spec/mocks/comment.rb",
     "spec/mocks/mock_adapter.rb",
     "spec/mocks/post.rb",
     "spec/mocks/user.rb",
     "spec/spec_helper.rb",
     "tasks/gemspec.rake",
     "tasks/rcov.rake",
     "tasks/rdoc.rake",
     "tasks/spec.rake",
     "tasks/todo.rake"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/outoftime/sunspot}
  s.rdoc_options = ["--charset=UTF-8", "--webcvs=http://github.com/outoftime/sunspot/tree/master/%s", "--title", "Sunspot - Pure-Ruby Solr Search and Indexing - API Documentation", "--main", "README.rdoc"]
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
     "spec/integration/test_pagination.rb",
     "spec/mocks/base_class.rb",
     "spec/mocks/mock_adapter.rb",
     "spec/mocks/user.rb",
     "spec/mocks/post.rb",
     "spec/mocks/comment.rb",
     "spec/api/search_retrieval_spec.rb",
     "spec/api/spec_helper.rb",
     "spec/api/session_spec.rb",
     "spec/api/build_search_spec.rb",
     "spec/api/indexer_spec.rb",
     "spec/api/query_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<solr-ruby>, [">= 0.0.6"])
      s.add_development_dependency(%q<rspec>, ["~> 1.1"])
      s.add_development_dependency(%q<ruby-debug>, ["~> 0.10"])
    else
      s.add_dependency(%q<solr-ruby>, [">= 0.0.6"])
      s.add_dependency(%q<rspec>, ["~> 1.1"])
      s.add_dependency(%q<ruby-debug>, ["~> 0.10"])
    end
  else
    s.add_dependency(%q<solr-ruby>, [">= 0.0.6"])
    s.add_dependency(%q<rspec>, ["~> 1.1"])
    s.add_dependency(%q<ruby-debug>, ["~> 0.10"])
  end
end
