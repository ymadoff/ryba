
# MongoDB Start

This commands starts MongoDB daemon using the default service command.

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'MongoDB # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'mongod'

