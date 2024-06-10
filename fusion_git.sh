#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <git_owner> <git_repo> <git_file> <fusion_clusterID>"
    exit 1
fi

# Assign script arguments to variables
git_owner="$1"
git_repo="$2"
git_file="$3"
fusion_clusterID="$4"

# Securely assign sensitive information (use environment variables for sensitive data if possible)
token="ghp_token"  # Replace with $GITHUB_TOKEN if using environment variables
api_endpoint="http://fusion_url:4445"
api_user="user"  # Replace with $API_USER if using environment variables
api_password="pwd"  # Replace with $API_PASSWORD if using environment variables

# GitHub API URL for the file content
git_api="https://api.github.com/repos/${git_owner}/${git_repo}/contents/${git_file}"

# Temporary files
haproxy="haproxy.cfg"
old_md5_file="old_haproxy_md5"

# Fetch the file content from GitHub and decode the base64 content
haproxy_git_file=$(curl -s -H "Authorization: token ${token}" "${git_api}" | jq -r '.content' | base64 --decode)

# Check if the content was fetched successfully
if [ -z "$haproxy_git_file" ]; then
    echo "Failed to fetch file content."
    exit 1
fi

# Save the new content to a temporary file
echo -e "$haproxy_git_file" > "$haproxy"

# Calculate MD5 checksum of the new haproxy.cfg
new_md5=$(md5sum "$haproxy" | awk '{ print $1 }')

# Check if previous MD5 checksum exists and compare
if [ -f "$old_md5_file" ]; then
    old_md5=$(cat "$old_md5_file")

    if [ "$new_md5" == "$old_md5" ]; then
        echo "No changes in configuration."
        rm "$haproxy"
        exit 0
    fi
fi

# Save the new MD5 checksum
echo "$new_md5" > "$old_md5_file"

# Fetch configuration version
version_id=$(curl -s -u "${api_user}:${api_password}" -X GET "${api_endpoint}/v1/clusters/${fusion_clusterID}/services/haproxy/configuration/version")

# Check if version_id was fetched successfully
if [ -z "$version_id" ]; then
    echo "Failed to fetch version ID."
    rm "$haproxy"
    exit 1
fi

# Post the raw configuration file to the specified API endpoint
response=$(curl -s -u "${api_user}:${api_password}" -X PUT "${api_endpoint}/v1/clusters/${fusion_clusterID}/services/haproxy/configuration/raw?version=${version_id}" -H "Content-Type: text/plain" --data-binary @"$haproxy")

# Check the response from the API
echo "Fusion HAProxy Configuration successfully updated for Fusion Cluster $fusion_clusterID."

# Clean up the temporary file
rm "$haproxy"
