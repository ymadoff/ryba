
# Spark SQL Thrift server Stop

Stops the Spark SQL Thrift server. You can also start the server manually with the
following command:

```
service spark-thrift-server start
```

    module.exports = header: 'Spark SQL Thrift Server Stop', label_true: 'STOPPED', handler: ->
      {spark} = @config.ryba
      @service.stop
        name: 'spark-thrift-server'

## Clean Logs

      @call header: 'Clean Logs', label_true: 'CLEANED', handler: ->
        return unless @config.ryba.clean_logs
        @system.execute
          cmd: "rm #{spark.thrift.log_dir}/*"
          code_skipped: 1
