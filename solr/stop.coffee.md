
# Solr Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Stop

    module.exports.push name: 'Solr # Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'solr'
        if_exists: '/etc/init.d/solr'
