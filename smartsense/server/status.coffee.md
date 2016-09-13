
# HST Server Status

    module.exports = header: 'HST Server Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'hst-server'
        if_exists: '/etc/init.d/hst-server'
