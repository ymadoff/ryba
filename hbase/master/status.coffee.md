
# HBase Master Status

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Status

Check if the HBase Master is running. The process ID is located by default
inside "/var/run/hbase/hbase-hbase-master.pid".

    module.exports.push header: 'HBase Master # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: "service hbase-master status"
        code_skipped: 3
        if_exists: '/etc/init.d/hbase-master'
