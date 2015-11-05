
# MapReduce JobHistoryServer Status

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Status

Check if the Job History Server is running. The process ID is located by default
inside "/var/run/hive/hive-server2.pid".

    module.exports.push header: 'MapReduce JHS # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: 'service hadoop-mapreduce-historyserver status'
        code_skipped: 3
        if_exists: '/etc/init.d/hadoop-mapreduce-historyserver'
