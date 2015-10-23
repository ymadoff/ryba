
# MongoDB Client Install

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/yum'

## Packages

    module.exports.push name: 'MongoDB Client # Packages', timeout: -1, handler: ->
      @service name: 'mongodb-org-shell'
      @service name: 'mongodb-org-tools'
      

