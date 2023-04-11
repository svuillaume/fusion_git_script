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
echo "Please enter Cluster ID?"
read CLUSTER_ID

# fetch current config
curl -k -s -X GET -H 'Content-Type: application/json' -H "Authorization: Basic $FUSION_AUTH" "$SCHEMA://$FUSION_HOSTNAME/v1/clusters/$CLUSTER_ID/services/haproxy/configuration/raw" > config_cluster_running.cfg

#get config version
VERSION=$(curl -s -X GET -H 'Content-Type: application/json' -H "Authorization: Basic $FUSION_AUTH" "$SCHEMA://$FUSION_HOSTNAME/v1/clusters/$CLUSTER_ID/services/haproxy/configuration/version")
echo $VERSION

md5_fusion=$(md5sum config_cluster_running.cfg | awk '{print $1}')
md5_git=$(md5sum config_cluster_git.cfg | awk '{print $1}')
echo $md5_fusion
echo $md5_git

sleep 1

if [ $md5_fusion -eq $md5_git ]
then
        echo "Git is already update witht the lastest fusion cluster config"
else
        cp ~/tmp/fusion_script/config_cluster_running.cfg ~/tmp/fusion_script/config_cluster_git.cfg
	git commit -a -m "fusion cluster latest configuration"
	git push origin main
fi


