
# Spark SQL Thrift server Start

Start the Spark SQL Thrift server. You can also start the server manually with the
following command:

```
service spark-thrift-server start
```

    module.exports = header: 'Spark SQL Thrift Server Start', label_true: 'STARTED', handler: ->
      {spark} = @config.ryba
      @call once:true, 'ryba/hive/hcatalog/wait'
      @service_start
        name: 'spark-thrift-server'
