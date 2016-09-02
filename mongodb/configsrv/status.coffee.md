
# MongoDB Config Server Status

    module.exports = header: 'MongoDB Config Server # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->

## Status

      @service.status name: 'mongodb-config-server'
