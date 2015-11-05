
# HBase Master Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop

Stop the RegionServer server. You can also stop the server manually with one of
the following two commands:

```
service hbase-master stop
su -l hbase -c "/usr/hdp/current/hbase-regionserver/bin/hbase-daemon.sh --config /etc/hbase/conf stop regionserver"
```

The file storing the PID is "/var/run/hbase/yarn/hbase-hbase-master.pid".

    module.exports.push header: 'HBase Master # Stop', label_true: 'STOPPED', handler: ->
      @service
        name: 'hbase-master'
        if_exists: '/etc/init.d/hbase-master'
        if: @retry is 0
      @execute
        cmd: 'service hbase-master force-stop'
        if_exists: '/etc/init.d/hbase-master'
        if: @retry > 0

## Stop Clean Logs

    module.exports.push
      header: 'HBase Master # Stop Clean Logs'
      label_true: 'CLEANED'
      if: -> @config.ryba.clean_logs
      handler: ->
        {hbase} = @config.ryba
        @execute
          cmd: "rm #{hbase.log_dir}/*-master-*"
          code_skipped: 1
        @execute
          cmd: "rm #{hbase.log_dir}/gc.log-*"
          code_skipped: 1
