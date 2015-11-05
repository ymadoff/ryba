
# Shinken Reactionner Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push header: 'Shinken Reactionner # Check TCP', label_true: 'CHECKED', handler: ->
      {reactionner} = @config.ryba.shinken
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{reactionner.port}"
  
    module.exports.push header: 'Shinken Reactionner # Check HTTP', label_true: 'CHECKED', handler: ->
      {reactionner} = @config.ryba.shinken
      @execute
        cmd: "curl http://#{@config.host}:#{reactionner.config.port} | grep OK"
