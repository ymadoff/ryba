
# MongoDB Config Server Start

    module.exports = header: 'MongoDB Config Server # Start', label_true: 'STARTED', handler: ->

## Start

      @service_start name: 'mongodb-config-server'

## Dependencies

    path = require 'path'
