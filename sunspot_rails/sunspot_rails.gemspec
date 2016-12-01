# -*- encoding: utf-8 -*-
lib = File.expand_path('../../sunspot/lib/', __FILE__)

$:.unshift(lib) unless $:.include?(lib)

require 'sunspot/version'

Gem::Specification.new do |s|
  s.name        = "sunspot_rails"
  s.version     = Sunspot::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Mat Brown', 'Peer Allan', 'Dmitriy Dzema', 'Benjamin Krause', 'Marcel de Graaf', 'Brandon Keepers', 'Peter Berkenbosch',
                  'Brian Atkinson', 'Tom Coleman', 'Matt Mitchell', 'Nathan Beyer', 'Kieran Topping', 'Nicolas Braem', 'Jeremy Ashkenas',
                  'Dylan Vaughn', 'Brian Durand', 'Sam Granieri', 'Nick Zadrozny', 'Jason Ronallo']
  s.email       = ["mat@patch.com"]
  s.homepage = 'http://github.com/outoftime/sunspot/tree/master/sunspot_rails'
  s.summary     = 'Rails integration for the Sunspot Solr search library'
  s.description = <<-TEXT
    Sunspot::Rails is an extension to the Sunspot library for Solr search.
    Sunspot::Rails adds integration between Sunspot and ActiveRecord, including
    defining search and indexing related methods on ActiveRecord models themselves,
    running a Sunspot-compatible Solr instance for development and test
    environments, and automatically commit Solr index changes at the end of each
    Rails request.
  TEXT

  s.rubyforge_project = "sunspot"

  s.files         = %w[
    LICENSE
    MIT-LICENSE
    README.rdoc
    Rakefile
    TODO
    dev_tasks/rdoc.rake
    dev_tasks/release.rake
    dev_tasks/spec.rake
    dev_tasks/todo.rake
    gemfiles/rails-2.3.14
    gemfiles/rails-3.0.12
    gemfiles/rails-3.1.4
    gemfiles/rails-3.2.3
    generators/sunspot/sunspot_generator.rb
    generators/sunspot/templates/sunspot.yml
    install.rb
    lib/generators/sunspot_rails.rb
    lib/generators/sunspot_rails/install/install_generator.rb
    lib/generators/sunspot_rails/install/templates/config/sunspot.yml
    lib/sunspot/rails.rb
    lib/sunspot/rails/adapters.rb
    lib/sunspot/rails/configuration.rb
    lib/sunspot/rails/init.rb
    lib/sunspot/rails/log_subscriber.rb
    lib/sunspot/rails/railtie.rb
    lib/sunspot/rails/railties/controller_runtime.rb
    lib/sunspot/rails/request_lifecycle.rb
    lib/sunspot/rails/searchable.rb
    lib/sunspot/rails/server.rb
    lib/sunspot/rails/solr_instrumentation.rb
    lib/sunspot/rails/solr_logging.rb
    lib/sunspot/rails/spec_helper.rb
    lib/sunspot/rails/stub_session_proxy.rb
    lib/sunspot/rails/tasks.rb
    lib/sunspot_rails.rb
    spec/configuration_spec.rb
    spec/model_lifecycle_spec.rb
    spec/model_spec.rb
    spec/rails_template/app/controllers/application_controller.rb
    spec/rails_template/app/controllers/posts_controller.rb
    spec/rails_template/app/models/author.rb
    spec/rails_template/app/models/blog.rb
    spec/rails_template/app/models/location.rb
    spec/rails_template/app/models/photo_post.rb
    spec/rails_template/app/models/post.rb
    spec/rails_template/app/models/post_with_auto.rb
    spec/rails_template/app/models/post_with_default_scope.rb
    spec/rails_template/config/boot.rb
    spec/rails_template/config/preinitializer.rb
    spec/rails_template/config/routes.rb
    spec/rails_template/config/sunspot.yml
    spec/rails_template/db/schema.rb
    spec/request_lifecycle_spec.rb
    spec/schema.rb
    spec/searchable_spec.rb
    spec/server_spec.rb
    spec/session_spec.rb
    spec/shared_examples/indexed_after_save.rb
    spec/shared_examples/not_indexed_after_save.rb
    spec/spec_helper.rb
    spec/stub_session_proxy_spec.rb
    sunspot_rails.gemspec
  ]

  s.test_files    = %w[
    spec/configuration_spec.rb
    spec/model_lifecycle_spec.rb
    spec/model_spec.rb
    spec/rails_template/app/controllers/application_controller.rb
    spec/rails_template/app/controllers/posts_controller.rb
    spec/rails_template/app/models/author.rb
    spec/rails_template/app/models/blog.rb
    spec/rails_template/app/models/location.rb
    spec/rails_template/app/models/photo_post.rb
    spec/rails_template/app/models/post.rb
    spec/rails_template/app/models/post_with_auto.rb
    spec/rails_template/app/models/post_with_default_scope.rb
    spec/rails_template/config/boot.rb
    spec/rails_template/config/preinitializer.rb
    spec/rails_template/config/routes.rb
    spec/rails_template/config/sunspot.yml
    spec/rails_template/db/schema.rb
    spec/request_lifecycle_spec.rb
    spec/schema.rb
    spec/searchable_spec.rb
    spec/server_spec.rb
    spec/session_spec.rb
    spec/shared_examples/indexed_after_save.rb
    spec/shared_examples/not_indexed_after_save.rb
    spec/spec_helper.rb
    spec/stub_session_proxy_spec.rb
  ]

  s.executables   = []
  s.require_paths = ["lib"]

  s.add_dependency 'sunspot', Sunspot::VERSION
  s.add_dependency 'nokogiri'

  s.add_development_dependency 'rspec', '~> 1.2'
  s.add_development_dependency 'rspec-rails', '~> 1.2'

  s.rdoc_options << '--webcvs=http://github.com/outoftime/sunspot/tree/master/%s' <<
                  '--title' << 'Sunspot-Rails - Rails integration for the Sunspot Solr search library - API Documentation' <<
                  '--main' << 'README.rdoc'
end
