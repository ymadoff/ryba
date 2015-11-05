# Spark History Web UI Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop

Stop the History server. You can also stop the server manually with the
following command:

```
su -l spark -c '/usr/hdp/current/spark-historyserver/sbin/stop-history-server.sh'
```

    module.exports.push header: 'Spark History Server # Stop', label_true: 'STOPPED', handler: ->
      {spark} = @config.ryba
      @execute
        cmd:  """
        su -l #{spark.user.name} -c '/usr/hdp/current/spark-historyserver/sbin/stop-history-server.sh'
        """
        if_exists: '/usr/hdp/current/spark-historyserver/sbin/stop-history-server.sh'
