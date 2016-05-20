
# Solr Start

    module.exports =  header: 'Solr Cloud Start', label_true: 'STARTED', handler: ->

## Dependencies

      @call 'ryba/zookeeper/server/wait'
      
      @execute
        if_exists: '/etc/init.d/solr'
        cmd: 'service solr start'
        unless_exec: 'service solr status | grep \'running on port\''
        code_skipped: 1
        
