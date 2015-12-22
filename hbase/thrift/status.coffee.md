
# HBase Thrift Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

Check if the Rest is running. The process ID is located by default inside
"/var/run/hbase/hbase-hbase-thrift.pid".

    module.exports.push header: 'HBase Thrift # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hbase-thrift'
        if_exists: '/etc/init.d/hbase-thrift'
