#!/bin/sh
set -e -x

cd sunspot
bundle install
bundle exec sunspot-solr start -p 8983
sleep 5