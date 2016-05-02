
# HBase Master Stop

Stop the RegionServer server. You can also stop the server manually with one of
the following two commands:

```
service hbase-master stop
su -l hbase -c "/usr/hdp/current/hbase-master/bin/hbase-daemon.sh --config /etc/hbase/conf stop master"
```

The file storing the PID is "/var/run/hbase/yarn/hbase-hbase-master.pid".

    module.exports = header: 'HBase Master Stop', label_true: 'STOPPED', handler: ->
      {hbase} = @config.ryba
      @call header: 'Service',  handler: ->
        @service_stop
          name: 'hbase-master'
          if_exists: '/etc/init.d/hbase-master'
          if: @retry is 0
        @execute
          cmd: 'service hbase-master force-stop'
          if_exists: '/etc/init.d/hbase-master'
          if: @retry > 0

## Stop Clean Logs

      @call  
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: -> @config.ryba.clean_logs
        handler: ->        
          @execute
            cmd: "rm #{hbase.master.log_dir}/*-master-*"
            code_skipped: 1
          @execute
            cmd: "rm #{hbase.master.log_dir}/gc.log-*"
            code_skipped: 1
