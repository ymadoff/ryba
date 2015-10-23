
# MongoDB Routing Server Start

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Start

    module.exports.push name: 'MongoDB Routing Server # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'mongos'


