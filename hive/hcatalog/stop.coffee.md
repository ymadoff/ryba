
# Hive HCatalog Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

## Stop Hive Metastore

Stop the Hive HCatalog server. You can also stop the server manually with one of
the following two commands:

```
service hive-hcatalog-server stop
su -l hive -c "kill `cat /var/lib/hive-hcatalog/hcat.pid`"
```

    module.exports.push name: 'Hive HCatalog # Stop Hive Metastore', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'hive-hcatalog-server'
        action: 'stop'
        if_exists: '/etc/init.d/hive-hcatalog-server'

## Stop Clean Logs

    module.exports.push
      name: 'Hive HCatalog # Stop Clean Logs'
      label_true: 'CLEANED'
      if: -> @config.ryba.clean_logs
      handler: ->
        # TODO: get path from config
        @execute
          cmd: 'rm /var/log/hive-hcatalog/*'
          code_skipped: 1
