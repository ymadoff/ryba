
# Hadoop ZKFC Status

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Status

Check if the ZKFC daemon is running. The process ID is located by default
inside "/var/run/hadoop-hdfs/hdfs/hadoop-hdfs-zkfc.pid".

    module.exports.push header: 'HDFS ZKFC # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hadoop-hdfs-zkfc'
        if_exists: '/etc/init.d/hadoop-hdfs-zkfc'
