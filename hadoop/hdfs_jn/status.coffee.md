
# Hadoop HDFS JournalNode Status

Display the status of the JournalNode as "STARTED" or "STOPPED".

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Status

Check if the JournalNode Server is running. The process ID is located by default
inside "/var/lib/hadoop-hdfs/hdfs/hadoop-hdfs-journalnode.pid".

    module.exports.push header: 'HDFS JN # Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        name: 'hadoop-hdfs-journalnode'
        if_exists: '/etc/init.d/hadoop-hdfs-journalnode'
