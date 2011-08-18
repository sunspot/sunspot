#!/bin/sh

set -e

case $GEM in
  "sunspot")
  
    /bin/echo -n "Starting Solr on port 8983 for Sunspot specs... "
    cd sunspot
    bundle install --quiet --path vendor/bundle
    bundle exec sunspot-solr start -p 8983
    sleep 10
    /bin/echo "done."
    
    # Invoke the sunspot specs
    bundle exec rake spec
    
    /bin/echo -n "Stopping Solr... "
    bundle exec sunspot-solr stop
    /bin/echo "done."
    ;;
    
  "sunspot_rails")
  
    /bin/echo -n "Starting Solr on port 8980 for sunspot_rails... "
    cd sunspot
    bundle install --quiet --path vendor/bundle
    bundle exec sunspot-solr start -p 8980
    sleep 10
    /bin/echo "done."
    
    # Install gems for test Rails application
    cd ../sunspot_rails/spec/$RAILS
    bundle install --path vendor/bundle
    
    # Invoke the specs, pointing to the test Rails application
    cd ../..
    if [ "$RAILS" = "rails2" ]; then spec_cmd=spec; else spec_cmd=rspec; fi
    BUNDLE_GEMFILE=spec/$RAILS/Gemfile RAILS_ROOT=spec/$RAILS \
      bundle exec $spec_cmd spec/*_spec.rb --color

    # Cleanup Solr
    /bin/echo -n "Stopping Solr... "
    cd ../sunspot
    bundle exec sunspot-solr stop
    /bin/echo "done."
    ;;
    
  *)
esac
