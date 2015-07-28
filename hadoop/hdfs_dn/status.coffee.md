
# Hadoop HDFS DataNode Status

Display the status of the NameNode as "STARTED" or "STOPPED".

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push require('./index').configure

## Status

Check if the HDFS DataNode server is running. The process ID is located by default
inside "/var/run/hadoop-hdfs/hadoop-hdfs-datanode.pid".

    module.exports.push name: 'HDFS NN # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: 'service hadoop-hdfs-datanode status'
        code_skipped: 3
        if_exists: '/etc/init.d/hadoop-hdfs-datanode'
      .then next
