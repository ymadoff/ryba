

# XASecure Policy Manager

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'XASecure PolicyMgr # Start', label_true: 'STARTED', timeout: -1, handler: ->
      ctx.service_start
        name: 'xapolicymgr'
      
