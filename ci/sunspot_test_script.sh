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

  if [ "$(printf "%s\n" "3.2" "$RUBY_VERSION" | sort -V | tail -n1)" = "$RUBY_VERSION" ]; then
    bundle config set --local path 'vendor/bundle'
    bundle install --quiet
  else
    bundle install --quiet --path vendor/bundle
  fi

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
    
    if [ "$(printf "%s\n" "3.2" "$RUBY_VERSION" | sort -V | tail -n1)" = "$RUBY_VERSION" ]; then
      bundle config set --local path 'vendor/bundle'
      bundle install --quiet
    else
      bundle install --quiet --path vendor/bundle
    fi

    start_solr_server

    # Invoke the sunspot specs
    bundle exec appraisal install && bundle exec appraisal rake spec
    rv=$?

    stop_solr_server

    exit $rv
    ;;

  "sunspot_rails")

    cd sunspot
    if [ "$(printf "%s\n" "3.2" "$RUBY_VERSION" | sort -V | tail -n1)" = "$RUBY_VERSION" ]; then
      bundle config set --local path 'vendor/bundle'
      bundle install --quiet
    else
      bundle install --quiet --path vendor/bundle
    fi

    start_solr_server

    cd ../sunspot_rails

    if [ "$(printf "%s\n" "3.2" "$RUBY_VERSION" | sort -V | tail -n1)" = "$RUBY_VERSION" ]; then
      bundle config set --local path 'vendor/bundle'
      bundle install --quiet
    else
      bundle install --quiet --path vendor/bundle
    fi

    gem list
    bundle exec appraisal install && bundle exec appraisal rspec
    rv=$?

    cd ../sunspot
    stop_solr_server

    exit $rv
    ;;

  "sunspot_solr")

    cd sunspot_solr
    
    if [ "$(printf "%s\n" "3.2" "$RUBY_VERSION" | sort -V | tail -n1)" = "$RUBY_VERSION" ]; then
      bundle config set --local path 'vendor/bundle'
      bundle install --quiet
    else
      bundle install --quiet --path vendor/bundle
    fi

    bundle exec rake spec
    exit $?
    ;;
  *)
esac
