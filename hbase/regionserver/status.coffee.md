
# HBase RegionServer Status

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Status

Check if the HBase RegionServer is running. The process ID is located by default
inside "/var/run/hbase/hbase-hbase-regionserver.pid".

    module.exports.push header: 'HBase RegionServer # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hbase-regionserver'
        code_stopped: [1, 3]
        if_exists: '/etc/init.d/hbase-regionserver'
