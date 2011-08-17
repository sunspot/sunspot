#!/bin/sh

case $GEM in
  "sunspot")
    cd sunspot
    bundle exec rake spec
    ;;
  "sunspot_rails")
    cd sunspot_rails/spec/$RAILS
    bundle install
    cd ../..
    rake spec:$RAILS
    ;;
  *)
esac
