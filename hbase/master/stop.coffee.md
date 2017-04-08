
# HBase Master Stop

Stop the RegionServer server. You can also stop the server manually with one of
the following two commands:

```
service hbase-master stop
su -l hbase -c "/usr/hdp/current/hbase-master/bin/hbase-daemon.sh --config /etc/hbase/conf stop master"
```

The file storing the PID is "/var/run/hbase/yarn/hbase-hbase-master.pid".

## Service

    module.exports = header: 'HBase Master Stop', label_true: 'STOPPED', handler: ->
      {hbase} = @config.ryba
      @service.stop
        header: 'Service'
        name: 'hbase-master'

## Clean Logs

      @call  
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: -> @config.ryba.clean_logs
      , ->
        @system.execute
          cmd: "rm #{hbase.master.log_dir}/*-master-*"
          code_skipped: 1
        @system.execute
          cmd: "rm #{hbase.master.log_dir}/gc.log-*"
          code_skipped: 1
