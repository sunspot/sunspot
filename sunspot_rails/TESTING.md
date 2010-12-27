# Testing `sunspot_rails`

Note: All the paths mentioned in here are relative to the current directory, or `sunspot/sunspot_rails`.

The `sunspot_rails` gem is tested with RSpec, and its spec suite is located in `spec`.

These specs are to be run against up to date Rails 2 and Rails 3 applications, included at `spec/rails2` and `spec/rails3`, respectively. The `spec_helper.rb` file loads the environment for these applications based on the `RAILS_ROOT` provided when invoking tests, outlined below.

## Start Solr

Specs expect to connect to Solr on `http://localhost:8980/solr`

    rake sunspot:solr:start

## Install dependencies

Each application uses Bundler to manage its dependencies. The `Gemfile` also installs the `sunspot` and `sunspot_rails` gems from your copies checked out locally. Because Bundler expands the full path to `sunspot` and `sunspot_rails`, we're excluding its generated `Gemfile.lock` file from version control.

    pushd spec/rails2
    bundle install
    cd ../rails3
    bundle install
		popd

## Invoke specs

The project contains wrapper scripts that set up the environment to run the
specs under Rails 2 and Rails 3 respectively:

    rake spec:rails2
    rake spec:rails3

Or you can run them both:

	 	rake spec
