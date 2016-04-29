
# ElasticSearch Stop

This commands stops ElasticSearch service.

    module.exports = header: 'ES Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'elasticsearch'
        if_exists: '/etc/init.d/elasticsearch'
