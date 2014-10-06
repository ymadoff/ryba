

# XASecure Policy Manager

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push name: 'XASecure PolicyMgr # Start', timeout: -1, callback: (ctx, next) ->
      ctx.service
        srv_name: 'xapolicymgr'
        action: 'start'
      , next
      

