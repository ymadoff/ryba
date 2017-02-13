
# Elasticsearch Stop

This commands stops Elasticsearch service.

    module.exports = header: 'ES Stop', label_true: 'STOPPED', handler: ->
      @service.stop
        name: 'elasticsearch'
        if_exists: '/etc/init.d/elasticsearch'
