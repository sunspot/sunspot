#!/bin/bash

PORT=8983

# delete old collections
curl -X GET "http://localhost:${PORT}/solr/admin/collections?action=DELETE&name=default"
curl -X GET "http://localhost:${PORT}/solr/admin/collections?action=DELETE&name=test"

# delete conf
curl -X DELETE "http://localhost:${PORT}/api/cluster/configs/static_schema_1_6"

# create conf
(cd solr/solr/configsets_v7/sunspot/conf/ && zip -r - *) | curl -X POST --header "Content-Type:application/octet-stream" --data-binary @- "http://localhost:${PORT}/solr/admin/configs?action=UPLOAD&name=static_schema_1_6"

# create collections
curl -X GET "http://localhost:${PORT}/solr/admin/collections?action=CREATE&name=test&numShards=1&replicationFactor=1&collection.configName=static_schema_1_6"
curl -X GET "http://localhost:${PORT}/solr/admin/collections?action=CREATE&name=default&numShards=1&replicationFactor=1&collection.configName=static_schema_1_6"
