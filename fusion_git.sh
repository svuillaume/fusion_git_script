#!/bin/bash

# Function to check if the correct number of arguments are provided
check_arguments() {
    if [ "$#" -ne 4 ]; then
        echo "Usage: $0 <git_owner> <git_repo> <git_file> <fusion_clusterID>"
        exit 1
    fi
}

# Function to fetch file content from GitHub
fetch_github_file() {
    local git_owner="$1"
    local git_repo="$2"
    local git_file="$3"
    local token="$4"
    local git_api="https://api.github.com/repos/${git_owner}/${git_repo}/contents/${git_file}"
    
    local content=$(curl -s -H "Authorization: token ${token}" "${git_api}" | jq -r '.content' | base64 --decode)
    if [ -z "$content" ]; then
        echo "Failed to fetch file content."
        exit 1
    fi
    echo "$content"
}

# Function to calculate MD5 checksum
calculate_md5() {
    local file="$1"
    md5sum "$file" | awk '{ print $1 }'
}

# Function to fetch configuration version
fetch_version_id() {
    local api_endpoint="$1"
    local api_user="$2"
    local api_password="$3"
    local fusion_clusterID="$4"
    
    local version_id=$(curl -s -u "${api_user}:${api_password}" -X GET "${api_endpoint}/v1/clusters/${fusion_clusterID}/services/haproxy/configuration/version")
    if [ -z "$version_id" ]; then
        echo "Failed to fetch version ID."
        exit 1
    fi
    echo "$version_id"
}

# Function to update configuration
update_configuration() {
    local api_endpoint="$1"
    local api_user="$2"
    local api_password="$3"
    local fusion_clusterID="$4"
    local version_id="$5"
    local haproxy_file="$6"
    
    local response=$(curl -s -u "${api_user}:${api_password}" -X PUT "${api_endpoint}/v1/clusters/${fusion_clusterID}/services/haproxy/configuration/raw?version=${version_id}" -H "Content-Type: text/plain" --data-binary @"${haproxy_file}")
    echo "Fusion HAProxy Configuration successfully updated for Fusion Cluster $fusion_clusterID."
}

# Main script logic
main() {
    # Check arguments
    check_arguments "$@"

    # Assign script arguments to variables
    local git_owner="$1"
    local git_repo="$2"
    local git_file="$3"
    local fusion_clusterID="$4"

    # Securely assign sensitive information (use environment variables for sensitive data if possible)
    local token="${GITHUB_TOKEN:-ghp_xxxxxxxxx}"  # Replace with $GITHUB_TOKEN if using environment variables
    local api_endpoint="http://<fusion_fqdn>:4445"
    local api_user="${API_USER:-admin}"  # Replace with $API_USER if using environment variables
    local api_password="${API_PASSWORD:-admin123}"  # Replace with $API_PASSWORD if using environment variables

    # Temporary files
    local haproxy="haproxy.cfg"
    local old_md5_file="old_haproxy_md5"

    # Fetch the file content from GitHub
    local haproxy_git_file
    haproxy_git_file=$(fetch_github_file "$git_owner" "$git_repo" "$git_file" "$token")

    # Save the new content to a temporary file
    echo -e "$haproxy_git_file" > "$haproxy"

    # Calculate MD5 checksum of the new haproxy.cfg
    local new_md5
    new_md5=$(calculate_md5 "$haproxy")

    # Check if previous MD5 checksum exists and compare
    if [ -f "$old_md5_file" ]; then
        local old_md5
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
    local version_id
    version_id=$(fetch_version_id "$api_endpoint" "$api_user" "$api_password" "$fusion_clusterID")

    # Update configuration
    update_configuration "$api_endpoint" "$api_user" "$api_password" "$fusion_clusterID" "$version_id" "$haproxy"

    # Clean up the temporary file
    rm "$haproxy"
}

# Execute the main function with all script arguments
main "$@"
