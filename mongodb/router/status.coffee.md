
# MongoDB Routing Server Status

    module.exports = header: 'MongoDB Routing Server Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->

## Status

      @service.status name: 'mongod-router-server'
