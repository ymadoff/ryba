
# HBase Rest Gateway Status

Check if the Rest is running. The process ID is located by default inside
"/var/run/hbase/hbase-hbase-rest.pid".

    module.exports = header: 'HBase Rest Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'hbase-rest'
        if_exists: '/etc/init.d/hbase-rest'
