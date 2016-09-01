# Spark Livy Server Web UI Start

Start the Spark Livy Serve server. You can also start the server manually with the
following command:

```
service spark-livy-server start
```

    module.exports = header: 'Spark Livy Server Start', label_true: 'STARTED', handler: ->
      @service_start
        name: 'spark-history-server'
        if_exists: '/etc/init.d/spark-livy-server'
