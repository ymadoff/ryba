
# HBase Thrift Server Stop

Stop the Rest server. You can also stop the server manually with one of
the following two commands:

```
service hbase-thrift start
su -l hbase -c "/usr/hdp/current/hbase-client/bin/hbase-daemon.sh --config /etc/hbase/conf stop rest"
```

    module.exports =  header: 'HBase Thrift Stop', label_true: 'STOPPED', handler: ->
      {hbase} = @config.ryba
      @service.stop
        name: 'hbase-thrift'

## Stop Clean Logs

      @call
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: -> @config.ryba.clean_logs
        handler: ->
          @execute
            cmd: "rm #{hbase.thrift.log_dir}/*-thrift-*"
            code_skipped: 1
          @execute
            cmd: "rm #{hbase.thrift.log_dir}/gc.log-*"
            code_skipped: 1
