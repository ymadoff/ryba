
# Spark SQL Thrift Status

Get Status of  the Spark SQL Thrift server. You can also start the server manually with the
following command:

```
service spark-thrift-server status
```

    module.exports = header: 'Spark SQL Thrift Server Status', label_true: 'STARTED', handler: ->
      {spark} = @config.ryba
      @service.status
        name: 'spark-thrift-server'
