
# Solr Start

    module.exports =  header: 'Solr Cloud Start', label_true: 'STARTED', handler: ->

## Dependencies

      @call 'ryba/zookeeper/server/wait'

      @connection.wait
        unless: (@contexts('ryba/solr/cloud')[0].config.host is @config.host)
        host: @contexts('ryba/solr/cloud')[0].config.host
        port: @contexts('ryba/solr/cloud')[0].config.ryba.solr.cloud.port
      @execute
        if_exists: '/etc/init.d/solr'
        cmd: 'service solr start'
        unless_exec: 'service solr status | grep \'running on port\''
        code_skipped: 1

