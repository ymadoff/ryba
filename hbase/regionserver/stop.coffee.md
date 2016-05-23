
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
      @service_stop
        name: 'hbase-regionserver'
        if_exists: '/etc/init.d/hbase-regionserver'

## Stop Clean Logs

      @call
        header: 'HBase RegionServer # Stop Clean Logs'
        label_true: 'CLEANED'
        if: -> @config.ryba.clean_logs
        handler: ->
          @execute
            cmd: "rm #{hbase.rs.log_dir}/*-regionserver-*"
            code_skipped: 1
          @execute
            cmd: "rm #{hbase.rs.log_dir}/gc.log-*"
            code_skipped: 1
