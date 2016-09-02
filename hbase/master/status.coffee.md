
# HBase Master Status

Check if the HBase Master is running. The process ID is located by default
inside "/var/run/hbase/hbase-hbase-master.pid".

    module.exports = header: 'HBase Master Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'hbase-master'
        if_exists: '/etc/init.d/hbase-master'
