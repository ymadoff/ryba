
# Shinken Broker Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./').configure

## Check

    module.exports.push name: 'Shinken Broker # Check Status', label_true: 'CHECKED', handler: (ctx, next) ->
      {broker} = ctx.config.ryba.shinken
      ctx
      .execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{broker.config.port}"
      .execute
        cmd: "curl http://#{ctx.config.host}:#{broker.config.port} | grep OK"
      .then next
