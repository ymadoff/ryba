
# Hadoop HDFS Secondary NameNode Status

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Status

Check if the HDFS Secondary NameNode server is running. The process ID is
located by default inside "/var/run/hadoop-hdfs/hdfs/hadoop-hdfs-secondarynamenode.pid".

    module.exports.push header: 'HDFS SNN # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        cmd: 'hadoop-hdfs-secondarynamenode'
        if_exists: '/etc/init.d/hadoop-hdfs-secondarynamenode'
