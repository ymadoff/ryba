
# Hadoop HDFS NameNode Status

Check if the HDFS NameNode server is running. The process ID is located by default
inside "/var/run/hadoop-hdfs/hdfs/hadoop-hdfs-namenode.pid".

    module.exports = header: 'HDFS NN Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'hadoop-hdfs-namenode'
        if_exists: '/etc/init.d/hadoop-hdfs-namenode'
