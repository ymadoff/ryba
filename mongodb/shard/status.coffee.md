
# MongoDB Shard Server Status

    module.exports = header: 'MongoDB Shard Server # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->

## Status

      @service.status name: 'mongodb-shard-server'
