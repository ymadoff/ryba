
# HBase Rest Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Status

Check if the Rest is running. The process ID is located by default inside
"/var/run/hbase/hbase-hbase-rest.pid".

    module.exports.push name: 'HBase Rest # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: "service hbase-rest status"
        code_skipped: 3
        if_exists: '/etc/init.d/hbase-rest'
      , next



