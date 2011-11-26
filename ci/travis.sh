#!/bin/sh

set -e

solr_responding() {
  port=$1
  curl "http://localhost:$port/solr/admin/ping"
}

wait_until_solr_responds() {
  port=$1
  while ! solr_responding $1; do
    /bin/echo -n "."
    sleep 1
  done

  sleep 3 # extra buffer?
}

case $GEM in
  "sunspot")
    
    cd sunspot
    /bin/echo -n "Starting Solr on port 8983 for Sunspot specs..."
    bundle install --quiet --path vendor/bundle
    if [ -f sunspot-solr.pid ]; then bundle exec sunspot-solr stop || true; fi

    bundle exec sunspot-solr start -p 8983 -d /tmp/solr
    wait_until_solr_responds 8983
    /bin/echo "done."
    
    # Invoke the sunspot specs
    bundle exec rake spec
    
    /bin/echo -n "Stopping Solr... "
    bundle exec sunspot-solr stop
    /bin/echo "done."
    ;;
    
  "sunspot_rails")
  
    cd sunspot
    /bin/echo -n "Starting Solr on port 8983 for Sunspot specs..."
    bundle install --quiet --path vendor/bundle
    if [ -f sunspot-solr.pid ]; then bundle exec sunspot-solr stop || true; fi

    bundle exec sunspot-solr start -p 8983 -d /tmp/solr
    wait_until_solr_responds 8983
    /bin/echo "done."
    
    # Install gems for test Rails application
    cd ../sunspot_rails
    rake spec RAILS=$RAILS
    
    # Cleanup Solr
    /bin/echo -n "Stopping Solr... "
    cd ../sunspot
    bundle exec sunspot-solr stop
    /bin/echo "done."
    ;;
    
  *)
esac
