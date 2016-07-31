
# Hue Stop

Stop the Hue server. You can also stop the server manually with the following
command:

```
service hue stop
```

    module.exports = header: 'Hue # Stop', label_true: 'STOPPED', handler: ->
      {hue} = @config.ryba
      @service_stop
        name: 'hue'
        if_exists: '/etc/init.d/hue'

## Stop Clean Logs

      @execute
        header: 'Stop Clean Logs'
        label_true: 'CLEANED'
        if: -> @config.ryba.clean_logs
        cmd: "rm #{hue.log_dir}/*"
        code_skipped: 1
