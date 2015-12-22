
# HBase Rest Gateway Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

Check if the Rest is running. The process ID is located by default inside
"/var/run/hbase/hbase-hbase-rest.pid".

    module.exports.push header: 'HBase Rest # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hbase-rest'
        if_exists: '/etc/init.d/hbase-rest'
