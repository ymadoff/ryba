
# MongoDB Config Server Start

    module.exports = header: 'MongoDB Config Server # Start', label_true: 'STARTED', handler: ->

## Start

      @service.start name: 'mongodb-config-server'

## Dependencies

    path = require 'path'
