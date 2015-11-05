
# Hive Server2 Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop

Stop the Hive Server2. You can also stop the server manually with one of
the following two commands:

```
service hive-server2 stop
su -l hive -c "kill `cat /var/run/hive-server2/hive-server2.pid`"
```

    module.exports.push header: 'Hive & Server2 # Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'hive-server2'

## Stop Clean Logs

    module.exports.push
      header: 'Hive & HCat # Stop Clean Logs'
      label_true: 'CLEANED'
      if: -> @config.ryba.clean_logs
      handler: ->
        # TODO: get path from config
        @execute
          cmd: 'rm /var/log/hive/*'
          code_skipped: 1
