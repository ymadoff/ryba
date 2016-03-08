
# MongoDB Client Install

    module.exports = header: 'MongoDB Client Packages', timeout: -1, handler: ->
      @service name: 'mongodb-org-shell'
      @service name: 'mongodb-org-tools'
