# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{sunspot}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mat Brown"]
  s.date = %q{2008-12-11}
  s.description = %q{}
  s.email = ["mat@patch.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "solr/README.txt", "solr/solr/README.txt", "solr/solr/conf/protwords.txt", "solr/solr/conf/stopwords.txt", "solr/solr/conf/synonyms.txt"]
  s.files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "config/hoe.rb", "config/requirements.rb", "lib/light_config.rb", "lib/sunspot.rb", "lib/sunspot/adapters.rb", "lib/sunspot/conditions.rb", "lib/sunspot/conditions_builder.rb", "lib/sunspot/configuration.rb", "lib/sunspot/field.rb", "lib/sunspot/field_builder.rb", "lib/sunspot/indexer.rb", "lib/sunspot/query.rb", "lib/sunspot/query_builder.rb", "lib/sunspot/restriction.rb", "lib/sunspot/scope_builder.rb", "lib/sunspot/search.rb", "lib/sunspot/session.rb", "lib/sunspot/type.rb", "lib/sunspot/util.rb", "lib/sunspot/version.rb", "log/test_solr.log", "setup.rb", "solr/README.txt", "solr/etc/jetty.xml", "solr/etc/webdefault.xml", "solr/exampledocs/books.csv", "solr/exampledocs/hd.xml", "solr/exampledocs/ipod_other.xml", "solr/exampledocs/ipod_video.xml", "solr/exampledocs/mem.xml", "solr/exampledocs/monitor.xml", "solr/exampledocs/monitor2.xml", "solr/exampledocs/mp500.xml", "solr/exampledocs/post.jar", "solr/exampledocs/post.sh", "solr/exampledocs/sd500.xml", "solr/exampledocs/solr.xml", "solr/exampledocs/spellchecker.xml", "solr/exampledocs/utf8-example.xml", "solr/exampledocs/vidcard.xml", "solr/lib/jetty-6.1.3.jar", "solr/lib/jetty-util-6.1.3.jar", "solr/lib/jsp-2.1/ant-1.6.5.jar", "solr/lib/jsp-2.1/core-3.1.1.jar", "solr/lib/jsp-2.1/jsp-2.1.jar", "solr/lib/jsp-2.1/jsp-api-2.1.jar", "solr/lib/servlet-api-2.5-6.1.3.jar", "solr/solr/README.txt", "solr/solr/bin/abc", "solr/solr/bin/abo", "solr/solr/bin/backup", "solr/solr/bin/backupcleaner", "solr/solr/bin/commit", "solr/solr/bin/optimize", "solr/solr/bin/readercycle", "solr/solr/bin/rsyncd-disable", "solr/solr/bin/rsyncd-enable", "solr/solr/bin/rsyncd-start", "solr/solr/bin/rsyncd-stop", "solr/solr/bin/scripts-util", "solr/solr/bin/snapcleaner", "solr/solr/bin/snapinstaller", "solr/solr/bin/snappuller", "solr/solr/bin/snappuller-disable", "solr/solr/bin/snappuller-enable", "solr/solr/bin/snapshooter", "solr/solr/conf/admin-extra.html", "solr/solr/conf/protwords.txt", "solr/solr/conf/schema.xml", "solr/solr/conf/scripts.conf", "solr/solr/conf/solrconfig.xml", "solr/solr/conf/stopwords.txt", "solr/solr/conf/synonyms.txt", "solr/solr/conf/xslt", "solr/solr/data/spell", "solr/start.jar", "solr/webapps/solr.war", "tasks/deployment.rake", "tasks/environment.rake", "tasks/rcov.rake", "tasks/solr.rake", "tasks/website.rake", "test/api/test_build_search.rb", "test/api/test_helper.rb", "test/api/test_indexer.rb", "test/api/test_retrieve_search.rb", "test/api/test_session.rb", "test/custom_expectation.rb", "test/integration/test_field_types.rb", "test/integration/test_helper.rb", "test/integration/test_keyword_search.rb", "test/integration/test_pagination.rb", "test/mocks/base_class.rb", "test/mocks/comment.rb", "test/mocks/mock_adapter.rb", "test/mocks/post.rb", "test/test_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{Sunspot is a Ruby library for expressive, powerful interaction with the Solr search engine.}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{sunspot}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{}
  s.test_files = ["test/api/test_build_search.rb", "test/api/test_helper.rb", "test/api/test_indexer.rb", "test/api/test_retrieve_search.rb", "test/api/test_session.rb", "test/integration/test_field_types.rb", "test/integration/test_helper.rb", "test/integration/test_keyword_search.rb", "test/integration/test_pagination.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<newgem>, [">= 1.0.6"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<newgem>, [">= 1.0.6"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<newgem>, [">= 1.0.6"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
