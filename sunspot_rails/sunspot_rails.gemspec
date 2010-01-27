# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{sunspot_rails}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mat Brown", "Peer Allan", "Michael Moen", "Benjamin Krause", "Adam Salter", "Brandon Keepers", "Paul Canavese"]
  s.date = %q{2010-01-27}
  s.description = %q{Sunspot::Rails is an extension to the Sunspot library for Solr search.
Sunspot::Rails adds integration between Sunspot and ActiveRecord, including
defining search and indexing related methods on ActiveRecord models themselves,
running a Sunspot-compatible Solr instance for development and test
environments, and automatically commit Solr index changes at the end of each
Rails request.
}
  s.email = %q{mat@patch.com}
  s.files = ["MIT-LICENSE", "Rakefile", "README.rdoc", "TODO", "History.txt", "VERSION.yml", "LICENSE", "lib/sunspot", "lib/sunspot/rails", "lib/sunspot/rails/spec_helper.rb", "lib/sunspot/rails/searchable.rb", "lib/sunspot/rails/version.rb", "lib/sunspot/rails/stub_session_proxy.rb", "lib/sunspot/rails/adapters.rb", "lib/sunspot/rails/configuration.rb", "lib/sunspot/rails/server.rb", "lib/sunspot/rails/tasks.rb", "lib/sunspot/rails/request_lifecycle.rb", "lib/sunspot/rails/solr_logging.rb", "lib/sunspot/rails.rb", "dev_tasks/gemspec.rake", "dev_tasks/todo.rake", "dev_tasks/rdoc.rake", "dev_tasks/release.rake", "generators/sunspot", "generators/sunspot/sunspot_generator.rb", "generators/sunspot/templates", "generators/sunspot/templates/sunspot.yml", "install.rb", "rails/init.rb", "spec/spec_helper.rb", "spec/session_spec.rb", "spec/stub_session_proxy_spec.rb", "spec/server_spec.rb", "spec/configuration_spec.rb", "spec/model_lifecycle_spec.rb", "spec/schema.rb", "spec/model_spec.rb", "spec/request_lifecycle_spec.rb", "spec/mock_app/app/controllers", "spec/mock_app/app/controllers/posts_controller.rb", "spec/mock_app/app/controllers/application_controller.rb", "spec/mock_app/app/controllers/application.rb", "spec/mock_app/app/models", "spec/mock_app/app/models/photo_post.rb", "spec/mock_app/app/models/blog.rb", "spec/mock_app/app/models/post_with_auto.rb", "spec/mock_app/app/models/author.rb", "spec/mock_app/app/models/post.rb", "spec/mock_app/db/schema.rb", "spec/mock_app/db/test.db", "spec/mock_app/vendor/plugins", "spec/mock_app/vendor/plugins/sunspot_rails", "spec/mock_app/config/database.yml", "spec/mock_app/config/environment.rb", "spec/mock_app/config/initializers", "spec/mock_app/config/initializers/session_store.rb", "spec/mock_app/config/initializers/new_rails_defaults.rb", "spec/mock_app/config/sunspot.yml", "spec/mock_app/config/environments", "spec/mock_app/config/environments/development.rb", "spec/mock_app/config/environments/test.rb", "spec/mock_app/config/routes.rb", "spec/mock_app/config/boot.rb", "spec/mock_app/tmp", "spec/mock_app/log", "spec/mock_app/solr"]
  s.homepage = %q{http://github.com/outoftime/sunspot_rails}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{sunspot}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Rails integration for the Sunspot Solr search library}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<escape>, [">= 0.0.4"])
      s.add_runtime_dependency(%q<sunspot>, ["= 1.0.0"])
      s.add_development_dependency(%q<rspec>, ["~> 1.2"])
      s.add_development_dependency(%q<rspec-rails>, ["~> 1.2"])
    else
      s.add_dependency(%q<escape>, [">= 0.0.4"])
      s.add_dependency(%q<sunspot>, ["= 1.0.0"])
      s.add_dependency(%q<rspec>, ["~> 1.2"])
      s.add_dependency(%q<rspec-rails>, ["~> 1.2"])
    end
  else
    s.add_dependency(%q<escape>, [">= 0.0.4"])
    s.add_dependency(%q<sunspot>, ["= 1.0.0"])
    s.add_dependency(%q<rspec>, ["~> 1.2"])
    s.add_dependency(%q<rspec-rails>, ["~> 1.2"])
  end
end
