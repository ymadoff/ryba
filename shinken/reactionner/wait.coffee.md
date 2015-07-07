
# Shinken Reactionner Wait

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/shinken/scheduler/wait'
    module.exports.push 'ryba/shinken/poller/wait'
    module.exports.push 'ryba/shinken/receiver/wait'
    module.exports.push require('./').configure

    module.exports.push name: 'Shinken Reactionner # Wait', label_true: 'READY', handler: (ctx, next) ->
      ctxs = ctx.contexts 'ryba/shinken/reactionner', require('./index').configure
      servers = for _ctx in ctxs
        host: _ctx.config.host, port: _ctx.config.ryba.shinken.reactionner.config.port
      ctx.waitIsOpen servers, next
