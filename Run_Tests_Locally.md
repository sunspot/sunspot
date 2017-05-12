# How We Run Rspec Tests Locally

We run the tests manually because we do not have the Travis service.
We made some tweaks that allow us to run the tests against Ruby 2.2.4
and Rails 4.2/5.0.  The steps are as follows.

## For `sunspot`

1. Start `solr`

    ```
    cd sunspot
    bundle install --quiet --path vendor/bundle
    if [ -f sunspot-solr.pid ]; then bundle exec sunspot-solr stop || true; fi
    bundle exec sunspot-solr start -p 8983
    while ! `curl -o /dev/null "http://localhost:8983/solr/admin/ping" > /dev/null 2>&1`; do /bin/echo -n "."; sleep 1; done
    ```

2. Run tests

    ```
    bundle exec rake spec
    ```

3. Stop `solr` after all tests passed

    ```
    bundle exec sunspot-solr stop
    ```

## For `sunspot-rails`

1. Start `solr`

    ```
    cd sunspot_rails
    bundle install --quiet --path vendor/bundle
    if [ -f sunspot-solr.pid ]; then bundle exec sunspot-solr stop || true; fi
    bundle exec sunspot-solr start -p 8983
    while ! `curl -o /dev/null "http://localhost:8983/solr/admin/ping" > /dev/null 2>&1`; do /bin/echo -n "."; sleep 1; done
    ```

2. Run tests using the tweaked version

    - Rails 4.2

        ```
        cp tmp_rails_4_2_0_app tmp/rails_4_2_0_app
        rake spec RAILS=4.2.0
        ```
    - Rails 5.0

        ```
        cp tmp_rails_5_0_app tmp/rails_5_0_app
        rake spec RAILS=5.0
        ```

3. Stop `solr` after all tests passed

    ```
    bundle exec sunspot-solr stop
    ```

## For `sunspot-solr`

1. Run tests

    ```
    cd sunspot_solr
    bundle install --quiet --path vendor/bundle
    bundle exec rake spec
    ```
