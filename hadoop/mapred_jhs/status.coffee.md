
# MapReduce JobHistoryServer Status

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Status

Check if the Job History Server is running. The process ID is located by default
inside "/var/run/hive/hive-server2.pid".

    module.exports.push name: 'MapReduce JHS # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: 'service hadoop-mapreduce-historyserver status'
        code_skipped: 3
        if_exists: '/etc/init.d/hadoop-mapreduce-historyserver'
      , next
