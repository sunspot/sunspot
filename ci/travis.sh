#!/bin/sh

set +e

export SUNSPOT_LIB_HOME=`pwd`

SOLR_PORT=8983

if [ "$SOLR_MODE" = "cloud" ]; then
  CLOUD_MODE=true
  MODE="--cloud"
else
  CLOUD_MODE=false
  MODE=""
fi


solr_responding() {
  curl -o /dev/null "http://localhost:${SOLR_PORT}/solr/admin/ping" > /dev/null 2>&1
}

start_solr_server() {
  # go to sunspot_solr folder and install dependencies
  current_path=`pwd`
  cd ../sunspot_solr
  bundle install --quiet --path vendor/bundle

  # stop solr of already running (but it should not be)
  if [ -f sunspot-solr.pid ]; then stop_solr_server || true; fi
  /bin/echo -n "Starting Solr on port ${SOLR_PORT} for Sunspot specs..."

  # start solr
  bundle exec sunspot-solr start -p ${SOLR_PORT} $MODE

  # wait while Solr is up and running
  while ! solr_responding; do
    /bin/echo -n "."
    sleep 1
  done
  /bin/echo "done."

  # uploading config in case of cloud mode
  if [ "${CLOUD_MODE}" = true ]; then
    sleep 10
    curl -X GET "http://127.0.0.1:${SOLR_PORT}/solr/admin/collections?action=DELETE&name=default"
    curl -X GET "http://127.0.0.1:${SOLR_PORT}/solr/admin/collections?action=DELETE&name=test"
    curl -X GET "http://127.0.0.1:${SOLR_PORT}/solr/admin/collections?action=DELETE&name=development"
    ./solr/bin/solr create -d solr/solr/configsets/sunspot -c default
    ./solr/bin/solr create -d solr/solr/configsets/sunspot -c test
    ./solr/bin/solr create -d solr/solr/configsets/sunspot -c development
    sleep 15
  fi

  cd $current_path
}

stop_solr_server() {
  cd ../sunspot_solr
  /bin/echo -n "Stopping Solr... "
  bundle exec sunspot-solr stop -p ${SOLR_PORT}
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
