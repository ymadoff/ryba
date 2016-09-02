
# Solr Stop

    module.exports = header: 'Solr Stop', label_true: 'STOPPED', handler: ->
      @service.stop
        name: 'solr'
        if_exists: '/etc/init.d/solr'
