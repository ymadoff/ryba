
# HBase RegionServer Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop

Stop the RegionServer server. You can also stop the server manually with one of
the following two commands:

```
service hbase-regionserver stop
su -l hbase -c "/usr/hdp/current/hbase-regionserver/bin/hbase-daemon.sh --config /etc/hbase/conf stop regionserver"
```

The file storing the PID is "/var/run/hbase/yarn/hbase-hbase-regionserver.pid".

    module.exports.push name: 'HBase RegionServer # Stop', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'hbase-regionserver'
        action: 'stop'
        if_exists: '/etc/init.d/hbase-regionserver'
        # relax: true
      # @execute
      #   cmd: 'service hbase-regionserver force-stop'
      #   if: -> @error -1

## Stop Clean Logs

    module.exports.push
      name: 'HBase RegionServer # Stop Clean Logs'
      label_true: 'CLEANED'
      if: -> @config.ryba.clean_logs
      handler: ->
        {hbase} = @config.ryba
        @execute
          cmd: "rm #{hbase.log_dir}/*-regionserver-*"
          code_skipped: 1
        @execute
          cmd: "rm #{hbase.log_dir}/gc.log-*"
          code_skipped: 1
