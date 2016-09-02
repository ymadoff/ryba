# Ranger Admin Stop

Stop the ranger admin service server. You can also stop the server
manually with the following command:

```
service ranger-admin stop
```

    module.exports = header: 'Ranger Admin Stop', label_true: 'STOPPED', handler: ->
      @service.start
        name: 'ranger-admin'

## Clean Logs

      @call header: 'Clean Logs', label_true: 'CLEANED', handler: ->
        return unless @config.ryba.clean_logs
        @execute
          cmd: 'rm /var/log/ranger/admin/*'
          code_skipped: 1
