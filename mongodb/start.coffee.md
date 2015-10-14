
# MongoDB Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    
## Start

    module.exports.push name: 'MongoDB # Start', label_true: 'STARTED', handler: ->
      @service_start name: 'mongod'
