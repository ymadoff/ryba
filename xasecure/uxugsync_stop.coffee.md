

# XASecure Policy Manager

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'XASecure Sync # Stop', timeout: -1, label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'uxugsync'
        action: 'stop'
      , next
      

