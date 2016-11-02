
# Solr Start

    module.exports =  header: 'Solr Cloud Start', label_true: 'STARTED', handler: ->

## Dependencies

      @call 'ryba/zookeeper/server/wait'

      @connection.wait
        unless: (@contexts('ryba/solr/cloud')[0].config.host is @config.host)
        host: @contexts('ryba/solr/cloud')[0].config.host
        port: @contexts('ryba/solr/cloud')[0].config.ryba.solr.cloud.port
      @service.start
        if_exists: '/etc/init.d/solr'
        name: 'solr'
