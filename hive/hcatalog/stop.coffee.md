
# Hive HCatalog Stop

Stop the Hive HCatalog server. You can also stop the server manually with one of
the following two commands:

```
service hive-hcatalog-server stop
su -l hive -c "kill `cat /var/lib/hive-hcatalog/hcat.pid`"
```

The file storing the PID is "/var/run/hive-server2/hive-server2.pid".

    module.exports = header: 'Hive HCatalog Stop Hive Metastore', label_true: 'STOPPED', handler: ->
      {clean_logs, hive} = @config.ryba

      @service.stop
        name: 'hive-hcatalog-server'

## Clean Logs

      @execute
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: -> clean_logs
        cmd: "rm #{hive.hcatalog.log_dir}/*"
        code_skipped: 1
