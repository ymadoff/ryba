
# Hadoop ZKFC Status

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Status

Check if the ZKFC daemon is running. The process ID is located by default
inside "/var/run/hadoop-hdfs/hdfs/hadoop-hdfs-zkfc.pid".

    module.exports.push name: 'ZKFC # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @execute
        cmd: 'service hadoop-hdfs-zkfc status'
        code_skipped: 3
        if_exists: '/etc/init.d/hadoop-hdfs-zkfc'
