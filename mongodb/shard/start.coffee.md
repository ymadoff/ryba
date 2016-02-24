
# MongoDB Shard Server Start

    module.exports = header: 'MongoDB Shard Server # Start', label_true: 'STARTED', handler: ->

## Start

      @service_start name: 'mongodb-shard-server'

## Dependencies

    path = require 'path'
