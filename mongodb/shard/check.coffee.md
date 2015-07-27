
# MongoDB Shard check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

    module.exports.push name: 'MongoDB Shard # Check TCP', label_true: 'CHECKED', handler: (ctx, next) ->
      {mongodb} = ctx.config.ryba
      ctx.execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{mongodb.config.port}"
      .then next
