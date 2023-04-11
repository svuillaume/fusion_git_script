#!/bin/bash
[ "$DEBUG" == 'true' ] && set -x

# Fusion host to use
SCHEMA="http"
FUSION_HOSTNAME=172.16.22.101:4445

# save Fusion API credentials for later
FUSION_USER=admin
FUSION_PASS=admin
FUSION_AUTH=$(echo -n "$FUSION_USER:$FUSION_PASS" | base64)

#raw config file
FILE=C:\Users\vuill\Postman\files\conf_update.cfg

#Retrieve Cluster CLUSTER_ID
echo "Please enter Cluster ID?"
read CLUSTER_ID

# fetch current config
curl -k -s -X GET -H 'Content-Type: application/json' -H "Authorization: Basic $FUSION_AUTH" "$SCHEMA://$FUSION_HOSTNAME/v1/clusters/$CLUSTER_ID/services/haproxy/configuration/raw" > config_cluster.cfg

#get config version
VERSION=$(curl -s -X GET -H 'Content-Type: application/json' -H "Authorization: Basic $FUSION_AUTH" "$SCHEMA://$FUSION_HOSTNAME/v1/clusters/$CLUSTER_ID/services/haproxy/configuration/version")
echo $VERSION

nano ~/tmp/fusion_script/config_cluster.cfg

# make a change 
# change a timeout or something obvious vi config.cfg

#update cluster config
curl -w '%{http_code}' -s -X POST -H 'Content-Type: text/plain' -H "Authorization: Basic $FUSION_AUTH" "$SCHEMA://$FUSION_HOSTNAME/v1/clusters/$CLUSTER_ID/services/haproxy/configuration/raw?force_reload=false&version=$VERSION" --data-binary @config_cluster.cfg
