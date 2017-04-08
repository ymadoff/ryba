
# HBase RegionServer Stop

Stop the RegionServer server. You can also stop the server manually with one of
the following two commands:

```
service hbase-regionserver stop
su -l hbase -c "/usr/hdp/current/hbase-regionserver/bin/hbase-daemon.sh --config /etc/hbase-regionserver/conf stop regionserver"
```

The file storing the PID is "/var/run/hbase/yarn/hbase-hbase-regionserver.pid".

    module.exports = header: 'HBase RegionServer Stop', label_true: 'STOPPED', handler: ->
      {hbase} = @config.ryba
      @service.stop
        header: 'Stop service'
        name: 'hbase-regionserver'

## Stop Clean Logs

      @call
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: -> @config.ryba.clean_logs
      , ->
        @system.execute
          cmd: "rm #{hbase.rs.log_dir}/*-regionserver-*"
          code_skipped: 1
        @system.execute
          cmd: "rm #{hbase.rs.log_dir}/gc.log-*"
          code_skipped: 1
