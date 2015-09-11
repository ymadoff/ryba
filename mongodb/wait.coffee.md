
# MongoDB Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'MongoDB # Wait', label_true: 'READY', timeout: -1, handler: (ctx, next) ->
      ctx.wait_connect
        servers: for db_ctx in ctx.contexts 'ryba/mongodb', require('./index').configure
          host: db_ctx.config.host
          port: db_ctx.config.ryba.mongodb.srv_config.port
      .then next
