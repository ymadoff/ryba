
# Hue Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/docker'

## Clean Logs dir

Clens the log directory

    module.exports.push name: 'Hue Docker # Clean Log', handler: ->
      @remove
        destination: hue_docker.log_dir

## Stop Server

Stops the Hue 'hue_server' container. You can also stop the server manually with the following
command:

```
docker stop hue_server
```


    module.exports.push name: 'Hue Docker # Stop', label_true: 'STOPPED', handler: ->
      {hue_docker} = @config.ryba
      @docker_stop
        container: 'hue_server'
