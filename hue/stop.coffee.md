
# Hue Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    # module.exports.push require('./index').configure

# Stop Server

Stop the Hue server. You can also stop the server manually with the following
command:

```
service hue stop
```

    module.exports.push name: 'Hue # Stop', label_true: 'STOPPED', handler: ->
      @service_stop
        name: 'hue'

## Stop Clean Logs

    module.exports.push
      name: 'Hue # Stop Clean Logs'
      label_true: 'CLEANED'
      if: -> @config.ryba.clean_logs
      handler: ->
        {hue} = @config.ryba
        @execute
          cmd: "rm #{hue.log_dir}/*"
          code_skipped: 1
