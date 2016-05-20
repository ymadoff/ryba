
# Solr Status

    module.exports = header: 'Solr Cloud Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status 
        name: 'solr'
        code_skipped: 1
