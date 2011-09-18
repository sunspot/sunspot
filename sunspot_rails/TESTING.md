# Testing `sunspot_rails`

Note: All the paths mentioned in here are relative to the current
directory, or `sunspot/sunspot_rails`.

The `sunspot_rails` gem is tested with RSpec, and its spec suite is
located in `spec`.

The specs are run against Rails 2 and Rails 3 applications which are
dynamically generated in `tmp/`

Because the applications are dynamically generated, the specs must be
run with the rake task (described below) and not simply with `rspec
spec`.

## Start Solr

Specs expect to connect to Solr on `http://localhost:8980/solr`

    sunspot-solr start -p 8980

## Invoke specs

To run the specs against every Rails version defined in
`gemfiles/rails-*`:

    rake spec

To run the specs against a specific version or versions of Rails:

    rake spec VERSIONS=2.3.14
    rake spec VERSIONS=2.3.14,3.0.10
