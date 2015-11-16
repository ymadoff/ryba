
# Hue Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/docker'

## Stop Server

Stops the Hue 'hue_server' container. You can also stop the server manually with the following
command:

```
docker stop hue_server
```

    module.exports.push name: 'Hue # Stop', label_true: 'STOPPED', handler: ->
      {hue} = @config.ryba
      @docker_stop
        container: 'hue_server'
