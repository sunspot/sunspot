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
  s.description = <<-TEXT
    Sunspot is a library providing a powerful, all-ruby API for the Solr search engine. Sunspot manages the configuration of persistent
    Ruby classes for search and indexing and exposes Solr's most powerful features through a collection of DSLs. Complex search operations
    can be performed without hand-writing any boolean queries or building Solr parameters by hand.
  TEXT

  s.rubyforge_project = "sunspot"

  s.files         = %w[
    Gemfile
    LICENSE
    Rakefile
    TODO
    VERSION.yml
    bin/sunspot-installer
    bin/sunspot-solr
    installer/config/schema.yml
    lib/light_config.rb
    lib/sunspot.rb
    lib/sunspot/adapters.rb
    lib/sunspot/composite_setup.rb
    lib/sunspot/configuration.rb
    lib/sunspot/data_extractor.rb
    lib/sunspot/dsl.rb
    lib/sunspot/dsl/adjustable.rb
    lib/sunspot/dsl/field_query.rb
    lib/sunspot/dsl/fields.rb
    lib/sunspot/dsl/fulltext.rb
    lib/sunspot/dsl/function.rb
    lib/sunspot/dsl/functional.rb
    lib/sunspot/dsl/more_like_this_query.rb
    lib/sunspot/dsl/paginatable.rb
    lib/sunspot/dsl/query_facet.rb
    lib/sunspot/dsl/restriction.rb
    lib/sunspot/dsl/restriction_with_near.rb
    lib/sunspot/dsl/scope.rb
    lib/sunspot/dsl/search.rb
    lib/sunspot/dsl/standard_query.rb
    lib/sunspot/field.rb
    lib/sunspot/field_factory.rb
    lib/sunspot/indexer.rb
    lib/sunspot/installer.rb
    lib/sunspot/installer/library_installer.rb
    lib/sunspot/installer/schema_builder.rb
    lib/sunspot/installer/solrconfig_updater.rb
    lib/sunspot/installer/task_helper.rb
    lib/sunspot/query.rb
    lib/sunspot/query/abstract_field_facet.rb
    lib/sunspot/query/boost_query.rb
    lib/sunspot/query/common_query.rb
    lib/sunspot/query/composite_fulltext.rb
    lib/sunspot/query/connective.rb
    lib/sunspot/query/date_field_facet.rb
    lib/sunspot/query/dismax.rb
    lib/sunspot/query/field_facet.rb
    lib/sunspot/query/filter.rb
    lib/sunspot/query/function_query.rb
    lib/sunspot/query/geo.rb
    lib/sunspot/query/highlighting.rb
    lib/sunspot/query/more_like_this.rb
    lib/sunspot/query/more_like_this_query.rb
    lib/sunspot/query/pagination.rb
    lib/sunspot/query/query_facet.rb
    lib/sunspot/query/restriction.rb
    lib/sunspot/query/scope.rb
    lib/sunspot/query/sort.rb
    lib/sunspot/query/sort_composite.rb
    lib/sunspot/query/standard_query.rb
    lib/sunspot/query/text_field_boost.rb
    lib/sunspot/schema.rb
    lib/sunspot/search.rb
    lib/sunspot/search/abstract_search.rb
    lib/sunspot/search/date_facet.rb
    lib/sunspot/search/facet_row.rb
    lib/sunspot/search/field_facet.rb
    lib/sunspot/search/highlight.rb
    lib/sunspot/search/hit.rb
    lib/sunspot/search/more_like_this_search.rb
    lib/sunspot/search/paginated_collection.rb
    lib/sunspot/search/query_facet.rb
    lib/sunspot/search/standard_search.rb
    lib/sunspot/server.rb
    lib/sunspot/session.rb
    lib/sunspot/session_proxy.rb
    lib/sunspot/session_proxy/abstract_session_proxy.rb
    lib/sunspot/session_proxy/class_sharding_session_proxy.rb
    lib/sunspot/session_proxy/id_sharding_session_proxy.rb
    lib/sunspot/session_proxy/master_slave_session_proxy.rb
    lib/sunspot/session_proxy/sharding_session_proxy.rb
    lib/sunspot/session_proxy/silent_fail_session_proxy.rb
    lib/sunspot/session_proxy/thread_local_session_proxy.rb
    lib/sunspot/setup.rb
    lib/sunspot/text_field_setup.rb
    lib/sunspot/type.rb
    lib/sunspot/util.rb
    lib/sunspot/version.rb
    log/.gitignore
    pkg/.gitignore
    script/console
    solr-1.3/etc/jetty.xml
    solr-1.3/etc/webdefault.xml
    solr-1.3/lib/jetty-6.1.3.jar
    solr-1.3/lib/jetty-util-6.1.3.jar
    solr-1.3/lib/jsp-2.1/ant-1.6.5.jar
    solr-1.3/lib/jsp-2.1/core-3.1.1.jar
    solr-1.3/lib/jsp-2.1/jsp-2.1.jar
    solr-1.3/lib/jsp-2.1/jsp-api-2.1.jar
    solr-1.3/lib/servlet-api-2.5-6.1.3.jar
    solr-1.3/solr/conf/elevate.xml
    solr-1.3/solr/conf/protwords.txt
    solr-1.3/solr/conf/schema.xml
    solr-1.3/solr/conf/solrconfig.xml
    solr-1.3/solr/conf/stopwords.txt
    solr-1.3/solr/conf/synonyms.txt
    solr-1.3/solr/lib/geoapi-nogenerics-2.1-M2.jar
    solr-1.3/solr/lib/gt2-referencing-2.3.1.jar
    solr-1.3/solr/lib/jsr108-0.01.jar
    solr-1.3/solr/lib/locallucene.jar
    solr-1.3/solr/lib/localsolr.jar
    solr-1.3/start.jar
    solr-1.3/webapps/solr.war
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
    solr/logs/.gitignore
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
    spec/api/adapters_spec.rb
    spec/api/binding_spec.rb
    spec/api/indexer/attributes_spec.rb
    spec/api/indexer/batch_spec.rb
    spec/api/indexer/dynamic_fields_spec.rb
    spec/api/indexer/fixed_fields_spec.rb
    spec/api/indexer/fulltext_spec.rb
    spec/api/indexer/removal_spec.rb
    spec/api/indexer/spec_helper.rb
    spec/api/indexer_spec.rb
    spec/api/query/advanced_manipulation_examples.rb
    spec/api/query/connectives_examples.rb
    spec/api/query/dsl_spec.rb
    spec/api/query/dynamic_fields_examples.rb
    spec/api/query/faceting_examples.rb
    spec/api/query/fulltext_examples.rb
    spec/api/query/function_spec.rb
    spec/api/query/geo_examples.rb
    spec/api/query/highlighting_examples.rb
    spec/api/query/more_like_this_spec.rb
    spec/api/query/ordering_pagination_examples.rb
    spec/api/query/scope_examples.rb
    spec/api/query/spec_helper.rb
    spec/api/query/standard_spec.rb
    spec/api/query/text_field_scoping_examples.rb
    spec/api/query/types_spec.rb
    spec/api/search/dynamic_fields_spec.rb
    spec/api/search/faceting_spec.rb
    spec/api/search/highlighting_spec.rb
    spec/api/search/hits_spec.rb
    spec/api/search/paginated_collection_spec.rb
    spec/api/search/results_spec.rb
    spec/api/search/search_spec.rb
    spec/api/search/spec_helper.rb
    spec/api/server_spec.rb
    spec/api/session_proxy/class_sharding_session_proxy_spec.rb
    spec/api/session_proxy/id_sharding_session_proxy_spec.rb
    spec/api/session_proxy/master_slave_session_proxy_spec.rb
    spec/api/session_proxy/sharding_session_proxy_spec.rb
    spec/api/session_proxy/silent_fail_session_proxy_spec.rb
    spec/api/session_proxy/spec_helper.rb
    spec/api/session_proxy/thread_local_session_proxy_spec.rb
    spec/api/session_spec.rb
    spec/api/spec_helper.rb
    spec/api/sunspot_spec.rb
    spec/ext.rb
    spec/helpers/indexer_helper.rb
    spec/helpers/query_helper.rb
    spec/helpers/search_helper.rb
    spec/integration/dynamic_fields_spec.rb
    spec/integration/faceting_spec.rb
    spec/integration/highlighting_spec.rb
    spec/integration/indexing_spec.rb
    spec/integration/keyword_search_spec.rb
    spec/integration/local_search_spec.rb
    spec/integration/more_like_this_spec.rb
    spec/integration/scoped_search_spec.rb
    spec/integration/spec_helper.rb
    spec/integration/stored_fields_spec.rb
    spec/integration/test_pagination.rb
    spec/mocks/adapters.rb
    spec/mocks/blog.rb
    spec/mocks/comment.rb
    spec/mocks/connection.rb
    spec/mocks/mock_adapter.rb
    spec/mocks/mock_class_sharding_session_proxy.rb
    spec/mocks/mock_record.rb
    spec/mocks/mock_sharding_session_proxy.rb
    spec/mocks/photo.rb
    spec/mocks/post.rb
    spec/mocks/super_class.rb
    spec/mocks/user.rb
    spec/spec_helper.rb
    sunspot.gemspec
    tasks/rdoc.rake
    tasks/schema.rake
    tasks/todo.rake
  ]

  s.test_files    = []
  s.executables   = %w[ sunspot-installer sunspot-solr ]

  s.require_paths = ["lib"]

  s.add_dependency 'rsolr', '~>1.0.7'
  s.add_dependency 'pr_geohash', '~>1.0'

  s.add_development_dependency 'rspec', '~>2.6.0'
  s.add_development_dependency 'hanna'

  s.rdoc_options << '--webcvs=http://github.com/outoftime/sunspot/tree/master/%s' <<
                  '--title' << 'Sunspot - Solr-powered search for Ruby objects - API Documentation' <<
                  '--main' << 'README.rdoc'
end
