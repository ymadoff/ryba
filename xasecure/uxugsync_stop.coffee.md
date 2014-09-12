

# XASecure Policy Manager

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push name: 'XASecure Sync # Stop', timeout: -1, callback: (ctx, next) ->
      ctx.service
        srv_name: 'uxugsync'
        action: 'stop'
      , (err, stoped) ->
        next err, if stoped then ctx.OK else ctx.PASS
      

