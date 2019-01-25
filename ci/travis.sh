#!/bin/bash

set +e

export SUNSPOT_LIB_HOME=`pwd`

SOLR_PORT=8983
NSOLR_INSTANCE=`cat docker-compose.yml | grep "image: solr" | wc -l`

if [ "${SOLR_MODE}" = "cloud" ]; then
  CLOUD_MODE=true
  MODE="--cloud"
else
  CLOUD_MODE=false
  MODE=""
fi


solr_responding() {
  curl -o /dev/null "http://localhost:${SOLR_PORT}/solr/admin/ping" > /dev/null 2>&1
}

solr_cloud_responding() {
  instance=`docker-compose logs --tail=100 | grep "Server Started" | wc -l`
  if [ $instance -eq "$NSOLR_INSTANCE" ]; then
    return 0
  else
    return 1
  fi
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

  cd $current_path
}

stop_solr_server() {
  cd ../sunspot_solr
  /bin/echo -n "Stopping Solr... "
  bundle exec sunspot-solr stop -p ${SOLR_PORT}
  /bin/echo "done."
}

start_solrcloud_server() {
  docker-compose down
  sleep 1

  docker-compose up -d
  sleep 10

  sleep 1
  while ! solr_cloud_responding; do
    /bin/echo -n "."
    sleep 1
  done
  /bin/echo "solr cloud up"

  current_path=`pwd`
  cd ../sunspot_solr

  sleep 15
  docker-compose exec solr1 /usr/bin/solr_init.sh

  sleep 15
  /bin/echo "done."
  cd $current_path
}

stop_solrcloud_server() {
  docker-compose down
}

start_server() {
  if [ "${CLOUD_MODE}" = true ]; then
    start_solrcloud_server
  else
    start_solr_server
  fi
}

stop_server() {
  if [ "${CLOUD_MODE}" = true ]; then
    stop_solrcloud_server
  else
    stop_solr_server
  fi
}

case $GEM in
  "sunspot")

    cd sunspot
    bundle install --quiet --path vendor/bundle

    start_server

    # Invoke the sunspot specs
    bundle exec appraisal install && bundle exec appraisal rake spec
    rv=$?

    stop_server

    exit $rv
    ;;

  "sunspot_rails")

    cd sunspot
    bundle install --quiet --path vendor/bundle

    start_server

    cd ../sunspot_rails
    bundle install --quiet --path vendor/bundle
    bundle exec appraisal install && bundle exec appraisal rspec
    rv=$?

    cd ../sunspot
    stop_server

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
