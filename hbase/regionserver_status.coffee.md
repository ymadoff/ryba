
# HBase RegionServer Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./regionserver').configure

## Status

Check if the HBase RegionServer is running. The process ID is located by default
inside "/var/run/hbase/hbase-hbase-regionserver.pid".

    module.exports.push name: 'HBase RegionServer # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: "service hbase-regionserver status"
        # code_skipped: [1, 3]
        code_skipped: 3
        if_exists: '/etc/init.d/hbase-regionserver'
      , next
