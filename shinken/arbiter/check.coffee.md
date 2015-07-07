
# Shinken Arbiter Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./').configure

## Check

    module.exports.push name: 'Shinken Arbiter # Check Configuration', label_true: 'CHECKED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'shinken'
        action: 'check'
      .then next

    module.exports.push name: 'Shinken Arbiter # Check TCP', label_true: 'CHECKED', handler: (ctx, next) ->
      {arbiter} = ctx.config.ryba.shinken
      ctx.execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{arbiter.config.port}"
      .then next
