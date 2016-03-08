
# Solr Stop

    module.exports = header: 'Solr Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'solr'
        if_exists: '/etc/init.d/solr'
