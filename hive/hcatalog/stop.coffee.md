
# Hive HCatalog Stop

Stop the Hive HCatalog server. You can also stop the server manually with one of
the following two commands:

```
service hive-hcatalog-server stop
su -l hive -c "kill `cat /var/lib/hive-hcatalog/hcat.pid`"
```

The file storing the PID is "/var/run/hive-server2/hive-server2.pid".

    module.exports = header: 'Hive HCatalog Stop Hive Metastore', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'hive-hcatalog-server'
        if_exists: '/etc/init.d/hive-hcatalog-server'

## Stop Clean Logs

      @call
        header: 'Hive HCatalog # Stop Clean Logs'
        label_true: 'CLEANED'
        if: -> @config.ryba.clean_logs
        handler: ->
          # TODO: get path from config
          @execute
            cmd: "rm #{hive.hcatalog.log_dir}/*"
            code_skipped: 1
