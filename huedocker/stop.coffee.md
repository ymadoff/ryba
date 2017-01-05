
# Hue Stop

    module.exports = header: 'Hue Docker Stop', handler: ->
      {hue_docker} = @config.ryba


Stops the Hue 'hue_server' container. You can also stop the server manually with the following
command:

```
docker stop hue_server
```

      @service.stop
        name: hue_docker.service

## Clean Logs dir

      @call
        header: 'Stop Clean Logs'
        label_true: 'CLEANED'
        if: -> @config.ryba.clean_logs
        handler: ->
          @execute
            cmd: "rm #{hue_docker.log_dir}/*.log"
            code_skipped: 1
