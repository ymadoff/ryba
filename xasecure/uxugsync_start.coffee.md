

# XASecure Policy Manager

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push name: 'XASecure Sync # Start', timeout: -1, callback: (ctx, next) ->
      ctx.service
        srv_name: 'uxugsync'
        action: 'start'
      , (err, started) ->
        next err, if started then ctx.OK else ctx.PASS
      

