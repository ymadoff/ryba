

# XASecure Policy Manager

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push header: 'XASecure Sync # Stop', timeout: -1, label_true: 'STOPPED', handler: ->
      @service.stop
        name: 'uxugsync'
