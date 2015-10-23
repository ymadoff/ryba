
# MongoDB Config Server Start

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Start

    module.exports.push name: 'MongoDB ConfigSrv # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'mongod-configsrv'

## Dependencies

    path = require 'path'
