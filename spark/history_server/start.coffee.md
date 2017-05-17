
# Spark History Server Start

Start the History server. You can also start the server manually with the
following command:

```
su -l spark -c '/usr/hdp/current/spark-historyserver/sbin/start-history-server.sh'
```

    module.exports = header: 'Spark History Server Start', label_true: 'STARTED', handler: ->
      {spark, hadoop_group} = @config.ryba
      @wait.execute
        cmd: mkcmd.hdfs @, """
        hdfs dfs -stat \"%u:%g\" #{spark.history.conf['spark.eventLog.dir']} | grep #{spark.user.name}:#{hadoop_group.name}
        """
      @service.start
        name: 'spark-history-server'
        if_exists: '/etc/init.d/spark-history-server'

# Dependencies

    mkcmd = require '../../lib/mkcmd'
