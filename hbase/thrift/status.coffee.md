
# HBase Thrift Status

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Status

Check if the Rest is running. The process ID is located by default inside
"/var/run/hbase/hbase-hbase-thrift.pid".

    module.exports.push header: 'HBase Thrift # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: "service hbase-thrift status"
        code_skipped: 3
        if_exists: '/etc/init.d/hbase-thrift'
