
# Solr Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

    module.exports.push header: 'Solr # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status name: 'solr'
