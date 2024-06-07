# fusion_script

#cluster_git.cfg is used as a test hapee.cfg file

In fusion_git.sh, Update local variable
 # update local variable 
    local token="${GITHUB_TOKEN:-ghp_xxxxxxxxx}"  # Replace with $GITHUB_TOKEN if using environment variables
    local api_endpoint="http://<fusion_fqdn>:4445"
    local api_user="${API_USER}"  # Replace with $API_USER if using environment variables
    local api_password="${API_PASSWORD}"  # Replace with $API_PASSWORD if using environment variables

1-) chmod +x fusion_git.sh
    fusion_git.sh checks github api for repo content change

2- Optional: cronjob job is required for regular git repo config check, or can be simply run manually.
   #example below, run the script every day at 2am
   crontab -e
   0 2 * * * /path/to/your/fusion_git.sh <git_owner> <git_repo> <git_file> <fusion_clusterID>

