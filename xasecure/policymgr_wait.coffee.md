
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./policymgr').configure

    module.exports.push timeout: -1, callback: (ctx, next) ->
      managers = ctx.hosts_with_module('ryba/xasecure/policymgr')
      return next() unless managers.length
      ctx.log "Wait for 'ryba/xasecure/policymgr'"
      ctx.waitIsOpen managers, 6080, (err) ->
        next err, ctx.PASS


