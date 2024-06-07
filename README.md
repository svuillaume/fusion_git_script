# fusion_script

1-) chmod +x fusion_git.sh
    fusion_git.sh checks github api for repo content change

2- Optional: cronjob job is required for regular git repo config check, or can be simply run manually.
   #example below, run the script every day at 2am
   crontab -e
   0 2 * * * /path/to/your/fusion_git.sh <git_owner> <git_repo> <git_file> <fusion_clusterID>

