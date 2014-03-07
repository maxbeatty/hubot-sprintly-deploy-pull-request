# Description:
#   Finds references to items in GitHub Pull Requests and marks them as deployed in Sprint.ly
#
# Dependencies:
#   "githubot"
#
# Configuration:
#   HUBOT_GITHUB_TOKEN - GitHub authentication token
#   HUBOT_GITHUB_USER - (optional) GitHub user/organization to identify owner of repository
#   HUBOT_SPRINTLY_TOKEN - (optional) Sprint.ly authentication token <email:api_key>
#   HUBOT_SPRINTLY_PRODUCT_ID - (optional) Sprint.ly product id
#
# Author:
#   maxbeatty

module.exports = (robot) ->
  github = require('githubot')(robot)

  robot.router.post '/hubot/sprintly-deploy-pull-request', (req, res) ->
    pullRequestNumbers = req.body.numbers.split ','

    if (queue = pullRequestNumbers.length) is 0
      return res.send 400, 'No pull request numbers specified in request. Will not continue.'

    if (repo = req.body.repo) is undefined
      return res.send 400, 'No repository specified in request. Cannot continue.'

    if (productId = req.body.productId || HUBOT_SPRINTLY_PRODUCT_ID) is undefined
      return res.send 400, 'No product id defined. Cannot continue.'

    if (owner = req.body.owner || process.env.HUBOT_GITHUB_USER) is undefined
      return res.send 400, 'No GitHub user defined. Cannot continue.'

    if (auth = req.body.auth || process.env.HUBOT_SPRINTLY_TOKEN) is undefined
      return res.send 400, 'No Sprint.ly auth defined. Cannot continue.'

    env = req.body.environment || 'production'

    regex = /(close|closes|closed|fix|fixed|fixes) (issue:|ticket:|bug:|item:|#)([0-9]+)/ig

    for number in pullRequestNumbers
      github.get "#{owner}/#{repo}/pulls/#{number}", (pr) ->
        itemNumbers = []
        # search body for references to items
        while (match = regex.exec(pr.body)) isnt null
          itemNumbers.push match[3] # ["fixes item:123", "fixes", "item:", "123"]

        robot.http("https://sprint.ly/api/products/#{productId}/deploys.json")
          .header('authorization', "Basic #{new Buffer(auth).toString('base64')}")
          .post({environment: env, numbers: itemNumbers.join(',') }) (err, sres, body) ->
            if err
              res.send 400, err
            else if sres.statusCode isnt 200
              res.send 400, body
            else
              robot.emit 'sdpr:done'

    github.handleErrors (response) ->
      # errors will already be logged by githubot
      robot.emit 'sdpr:done'

    robot.on 'sdpr:done', ->
      res.send 200 if --queue is 0
