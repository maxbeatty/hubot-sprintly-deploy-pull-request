Hubot Sprint.ly Deploy Pull Request
==================================

Search Pull Request descriptions to mark items as deployed in Sprint.ly

## Installation

1. In your hubot repo, `npm install hubot-sprintly-deploy-pull-request --save`
2. Add `hubot-sprintly-deploy-pull-request` to your `external-scripts.json`

You'll also need to set these environment variables:

- `HUBOT_GITHUB_TOKEN`: GitHub authentication token
- `HUBOT_GITHUB_USER`: (optional) GitHub user/organization to identify owner of repository
- `HUBOT_SPRINTLY_TOKEN`: (optional) Sprint.ly authentication token <email:api_key>
- `HUBOT_SPRINTLY_PRODUCT_ID`: (optional) Sprint.ly product id

If you don't have a GitHub token yet, run this:

```bash
curl -i https://api.github.com/authorizations -d '{"scopes":["repo"]}' -u "yourusername"
```

## Usage

In your deploy script, make a request to `http://your-hubot-host/hubot/sprintly-deploy-pull-request` with the following parameters:

- `numbers`: (_required_) comma-separated list of Pull Request / Issue numbers
- `repo`: (_required_) repository to find those numbers
- `owner`: owner of the repository (defaults to `process.env.HUBOT_GITHUB_USER`)
- `productId`: numeric id of Sprint.ly product (defaults to `process.env.HUBOT_SPRINTLY_PRODUCT_ID`)
- `auth`: Sprint.ly authentication token <email:api_key> (defaults to `process.env.HUBOT_SPRINTLY_TOKEN`)
- `env`: environment to which you just deployed to be used in Sprint.ly (defaults to 'production')

What you might add to your deploy script:

```bash
# repository name
projectName=yourproject

function sprintlyDeploy {
  # get last two git tags for git log. returns something like release123..release124
  tagDiff=`git tag -l "release-*" | sort --version-sort  | tail -n 2 | xargs echo | sed 's/ /../'`
  # get issue numbers from git log
  numbers=`git log --pretty=format:%s $tagDiff | egrep -o '#[0-9]+' | sed 's/#//g'`
  curl -X POST -d "numbers=$numbers&repo=$projectName&environment=$1" http://your-hubot-host/hubot/sprintly-deploy-pull-request
}

# you can use this function in other scripts that deploy to different environments
sprintlyDeploy production
```
