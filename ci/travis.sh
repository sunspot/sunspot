#!/bin/sh

case $GEM in
  "sunspot")
    cd sunspot
    bundle install
    bundle exec sunspot-solr start -p 8983
    sleep 5
    bundle exec rake spec
    ;;
  "sunspot_rails")
    cd sunspot
    bundle install
    bundle exec sunspot-solr start -p 8980
    sleep 5
    cd ../sunspot_rails/spec/$RAILS
    bundle install
    cd ../..
    rake spec:$RAILS
    ;;
  *)
esac
