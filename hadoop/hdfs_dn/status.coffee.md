
# Hadoop HDFS DataNode Status

Display the status of the NameNode as "STARTED" or "STOPPED".

Check if the HDFS DataNode server is running. The process ID is located by default
inside "/var/run/hadoop-hdfs/hadoop-hdfs-datanode.pid".

    module.exports = header: 'HDFS NN # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hadoop-hdfs-datanode'
        if_exists: '/etc/init.d/hadoop-hdfs-datanode'
