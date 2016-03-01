
# Hadoop HDFS JournalNode Status

Check if the JournalNode Server is running and display the status of the
JournalNode as "STARTED" or "STOPPED".The process ID is located by default
inside "/var/lib/hadoop-hdfs/hdfs/hadoop-hdfs-journalnode.pid".

    module.exports = header: 'HDFS JN # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hadoop-hdfs-journalnode'
        if_exists: '/etc/init.d/hadoop-hdfs-journalnode'
