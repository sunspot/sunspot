#!/bin/sh
cd sunspot
bundle install
bundle exec sunspot-solr run &
sleep 2