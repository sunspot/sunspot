#!/bin/bash

cd /opt/solr

./bin/solr create -d /etc/configsets/sunspot -c default
./bin/solr create -d /etc/configsets/sunspot -c test
./bin/solr create -d /etc/configsets/sunspot -c development
./bin/solr create -shards 2 -replicationFactor 2 -d /etc/configsets/sunspot -c greetings
