

# XASecure Policy Manager

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'XASecure Sync # Stop', timeout: -1, label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'uxugsync'
