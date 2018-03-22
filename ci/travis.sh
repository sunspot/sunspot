#!/bin/sh

set +e

gem update --system 1.8.25

SOLR_PORT=8983

solr_responding() {
  curl -o /dev/null "http://localhost:$SOLR_PORT/solr/admin/ping" > /dev/null 2>&1
}

start_solr_server() {
  /bin/echo -n "Starting Solr on port $SOLR_PORT for Sunspot specs..."
  bundle exec sunspot-solr start -p $SOLR_PORT
  while ! solr_responding; do
    /bin/echo -n "."
    sleep 1
  done
  /bin/echo "done."
}

stop_solr_server() {
  /bin/echo -n "Stopping Solr... "
  bundle exec sunspot-solr stop -p $SOLR_PORT
  /bin/echo "done."
}

case $GEM in
  "sunspot")

    cd sunspot
    bundle install --quiet --path vendor/bundle
    if [ -f sunspot-solr.pid ]; then stop_solr_server || true; fi

    start_solr_server

    # Invoke the sunspot specs
    bundle exec rake spec
    rv=$?

    stop_solr_server

    exit $rv
    ;;

  "sunspot_rails")

    cd sunspot
    bundle install --quiet --path vendor/bundle
    if [ -f sunspot-solr.pid ]; then stop_solr_server || true; fi

    start_solr_server

    # Install gems for test Rails application
    # Allow user to pass in SPEC_OPTS that are passed to spec in order to specify
    # things like the random test seed in order to replicate results from failed tests.
    # e.g. GEM=sunspot_rails RAILS=4.0.0 SPEC_OPTS="--order random:64549" travis.sh
    cd ../sunspot_rails
    rake spec RAILS=$RAILS SPEC_OPTS="$SPEC_OPTS"
    rv=$?

    cd ../sunspot
    stop_solr_server

    exit $rv
    ;;

  "sunspot_solr")

    cd sunspot_solr
    bundle install --quiet --path vendor/bundle
    bundle exec rake spec
    exit $?
    ;;
  *)
esac
