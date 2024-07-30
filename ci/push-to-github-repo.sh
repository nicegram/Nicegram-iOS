. ./fastlane-env.sh

target_branch=$1
commit_message=$2

current_branch=$(git symbolic-ref --short HEAD)

curl --request POST \
  --url 'https://api.bitbucket.org/2.0/repositories/mobyrix/nicegram-ios/pipelines' \
  --header 'Authorization: Bearer '$BITBUCKET_ACCESS_TOKEN'' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --data '
  {
  "target": {
    "type": "pipeline_ref_target",
    "ref_type": "branch",
    "ref_name": "'$current_branch'",
    "selector": {
      "type": "custom",
      "pattern": "push-to-github-repo"
    }
  },
  "variables": [
    {
      "key": "TargetBranch",
      "value": "'$target_branch'"
    },
    {
      "key": "CommitMessage",
      "value": "'$commit_message'"
    }
  ]
}'
