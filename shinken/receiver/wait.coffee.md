
# Shinken Receiver Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./').configure

    module.exports.push name: 'Shinken Receiver # Wait', label_true: 'READY', handler: (ctx, next) ->
      ctxs = ctx.contexts 'ryba/shinken/receiver', require('./index').configure
      servers = for _ctx in ctxs
        host: _ctx.config.host, port: _ctx.config.ryba.shinken.receiver.config.port
      ctx.waitIsOpen servers, next
