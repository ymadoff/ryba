
# MongoDB Server check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

    module.exports.push name: 'MongoDB # Check TCP', label_true: 'CHECKED', handler: (ctx, next) ->
      {mongodb} = ctx.config.ryba
      ctx.execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{mongodb.srv_config.port}"
      .then next

    module.exports.push name: 'MongoDB # Check Shell', skip: true, label_true: 'CHECKED', handler: (ctx, next) ->
      ctx.execute
        cmd: "mongo --shell --quiet <<< 'show collections' | grep 'system.indexes'"
      .then next
