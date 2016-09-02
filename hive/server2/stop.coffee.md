
# Hive Server2 Stop

Stop the Hive Server2. You can also stop the server manually with one of
the following two commands:

```
service hive-server2 stop
su -l hive -c "kill `cat /var/run/hive-server2/hive-server2.pid`"
```

    module.exports = header: 'Hive Server2 Stop', label_true: 'STOPPED', handler: ->
      {hive} = @config.ryba

      @service.stop
        name: 'hive-server2'
        if_exists: '/etc/init.d/hive-server2'

## Stop Clean Logs

      @call
        header: 'Stop Clean Logs'
        label_true: 'CLEANED'
        if: -> @config.ryba.clean_logs
        handler: ->
          @execute
            cmd: "rm #{hive.server2.log_dir}/*"
            code_skipped: 1
