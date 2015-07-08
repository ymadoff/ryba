
# Shinken Receiver Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./').configure

## Check

    module.exports.push name: 'Shinken Receiver # Check TCP', label_true: 'CHECKED', handler: (ctx, next) ->
      {receiver} = ctx.config.ryba.shinken
      ctx.execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{receiver.port}"
      .execute
        cmd: "curl http://#{ctx.config.host}:#{receiver.config.port} | grep OK"
      .then next
