
# Shinken Reactionner Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./').configure

## Check

    module.exports.push name: 'Shinken Reactionner # Check TCP', label_true: 'CHECKED', handler: (ctx, next) ->
      {reactionner} = ctx.config.ryba.shinken
      ctx.execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{reactionner.port}"
      .execute
        cmd: "curl http://#{ctx.config.host}:#{reactionner.config.port} | grep OK"
      .then next
