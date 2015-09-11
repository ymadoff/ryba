
# Solr Start

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Start

    module.exports.push name: 'Solr # Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'solr'
