#!/bin/sh

set +e

SOLR_PORT=8983
export SUNSPOT_LIB_HOME=`pwd`

solr_responding() {
  curl -o /dev/null "http://localhost:$SOLR_PORT/solr/admin/ping" > /dev/null 2>&1
}

start_solr_server() {
  # go to sunspot_solr folder and install dependencies
  current_path=`pwd`
  cd ../sunspot_solr
  bundle install --quiet --path vendor/bundle

  # stop solr of already running (but it should not be)
  if [ -f sunspot-solr.pid ]; then stop_solr_server || true; fi
  /bin/echo -n "Starting Solr on port $SOLR_PORT for Sunspot specs..."

  # start solr
  bundle exec sunspot-solr start -p $SOLR_PORT

  # wait while Solr is up and running
  while ! solr_responding; do
    /bin/echo -n "."
    sleep 1
  done
  /bin/echo "done."

  cd $current_path
}

stop_solr_server() {
  cd ../sunspot_solr
  /bin/echo -n "Stopping Solr... "
  bundle exec sunspot-solr stop -p $SOLR_PORT
  /bin/echo "done."
}

case $GEM in
  "sunspot")

    cd sunspot
    bundle install --quiet --path vendor/bundle

    start_solr_server

    # Invoke the sunspot specs
    bundle exec appraisal install && bundle exec appraisal rake spec
    rv=$?

    stop_solr_server

    exit $rv
    ;;

  "sunspot_rails")

    cd sunspot
    bundle install --quiet --path vendor/bundle

    start_solr_server

    cd ../sunspot_rails
    bundle install --quiet --path vendor/bundle
    bundle exec appraisal install && bundle exec appraisal rspec
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
