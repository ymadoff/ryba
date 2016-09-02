# Spark History Web UI Stop

Stop the History server. You can also stop the server manually with the
following command:

```
su -l spark -c '/usr/hdp/current/spark-historyserver/sbin/stop-history-server.sh'
```

    module.exports = header: 'Spark History Server Stop', label_true: 'STARTED', handler: ->
      {spark} = @config.ryba
      @service.stop
        name: 'spark-history-server'
        if_exists: '/etc/init.d/spark-history-server'
