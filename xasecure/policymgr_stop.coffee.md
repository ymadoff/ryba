
# XASecure Policy Manager

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push header: 'XASecure PolicyMgr # Stop', timeout: -1, label_true: 'STOPPED', handler: ->
      ctx.service_stop
        name: 'xapolicymgr'
      
