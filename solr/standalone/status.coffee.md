
# Solr Status

    module.exports = header: 'Solr Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status name: 'solr'
