
# MongoDB Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'MongoDB # Wait', label_true: 'READY', timeout: -1, handler: (ctx, next) ->
      db_ctxs = ctx.contexts 'ryba/mongodb', require('./index').configure
      servers = for db_ctx in db_ctxs
        host: db_ctx.config.host, port: db_ctx.config.ryba.mongodb.srv_config.port
      ctx.waitIsOpen servers, next
