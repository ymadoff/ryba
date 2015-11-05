
# HBase Rest Gateway Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop

Stop the Rest server. You can also stop the server manually with one of
the following two commands:

```
service hbase-rest start
su -l hbase -c "/usr/hdp/current/hbase-client/bin/hbase-daemon.sh --config /etc/hbase/conf stop rest"
```

    module.exports.push header: 'HBase Rest # Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'hbase-rest'
        if_exists: '/etc/init.d/hbase-rest'

## Stop Clean Logs

    module.exports.push
      header: 'HBase Rest # Stop Clean Logs'
      label_true: 'CLEANED'
      if: -> @config.ryba.clean_logs
      handler: ->
        {hbase, clean_logs} = @config.ryba
        @execute
          cmd: "rm #{hbase.log_dir}/*-rest-*"
          code_skipped: 1
        @execute
          cmd: "rm #{hbase.log_dir}/gc.log-*"
          code_skipped: 1
