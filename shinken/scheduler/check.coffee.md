
# Shinken Scheduler Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./').configure

## Check

    module.exports.push name: 'Shinken Scheduler # Check TCP', label_true: 'CHECKED', handler: (ctx, next) ->
      {scheduler} = ctx.config.ryba.shinken
      ctx.execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{scheduler.config.port}"
      .execute
        cmd: "curl http://#{ctx.config.host}:#{scheduler.config.port} | grep OK"
      .then next
