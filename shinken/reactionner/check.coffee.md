
# Shinken Reactionner Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push name: 'Shinken Reactionner # Check TCP', label_true: 'CHECKED', handler: ->
      {reactionner} = @config.ryba.shinken
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{reactionner.port}"
      @execute
        cmd: "curl http://#{@config.host}:#{reactionner.config.port} | grep OK"
