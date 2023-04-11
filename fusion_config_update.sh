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
#FILE=C:\Users\vuill\Postman\files\conf_update.cfg

#Retrieve Cluster CLUSTER_ID
CLUSTER_ID=$(curl -k -s -X GET -H 'Content-Type: application/json' -H "Authorization: Basic $FUSION_AUTH" "$SCHEMA://$FUSION_HOSTNAME/v1/clusters/" | jq -r ".[1].id")

#echo "Please enter Cluster ID?"
#read CLUSTER_ID

# fetch current config
curl -k -s -X GET -H 'Content-Type: application/json' -H "Authorization: Basic $FUSION_AUTH" "$SCHEMA://$FUSION_HOSTNAME/v1/clusters/$CLUSTER_ID/services/haproxy/configuration/raw" > /tmp/fusion_script/cluster.cfg

#get config version
#VERSION=$(curl -s -X GET -H 'Content-Type: application/json' -H "Authorization: Basic $FUSION_AUTH" "$SCHEMA://$FUSION_HOSTNAME/v1/clusters/$CLUSTER_ID/services/haproxy/configuration/version")
#echo $VERSION

md5_fusion=$(md5sum /tmp/fusion_script/cluster.cfg | awk '{print $1}')
md5_git=$(md5sum /tmp/fusion_script/cluster_git.cfg | awk '{print $1}')

if [ $md5_fusion == $md5_git ]
then
     echo "You have got the lastest config stored in GitHub"

else
     cp /tmp/fusion_script/cluster.cfg /tmp/fusion_script/cluster_git.cfg
     cd /tmp/fusion_script/
     git commit -a -m "fusion cluster latest configuration"
     git push
fi

