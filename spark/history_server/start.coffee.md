# Spark History Web UI Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Start

Start the History server. You can also start the server manually with the
following command:

```
su -l spark -c '/usr/hdp/current/spark-historyserver/sbin/start-history-server.sh'
```

    module.exports.push header: 'Spark HS # Start', label_true: 'STARTED', handler: ->
      {spark} = @config.ryba
      @execute
        cmd:  """
        su -l #{spark.user.name} -c '/usr/hdp/current/spark-historyserver/sbin/start-history-server.sh'
        """
        not_if_exists: "#{spark.pid_dir}/spark-#{spark.user.name}-org.apache.spark.deploy.history.HistoryServer-1.pid"
        not_if: ({}, callback) ->
          pidfile = "#{spark.pid_dir}/spark-#{spark.user.name}-org.apache.spark.deploy.history.HistoryServer-1.pid"
          pidfile_running @ssh, pidfile, callback

## Dependencies

    pidfile_running = require 'mecano/lib/misc/pidfile_running'
