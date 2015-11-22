
# Hue Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Clean Logs dir

Clens the log directory

    module.exports.push header: 'Hue Docker # Clean Log', handler: ->
      {hue_docker} = @config.ryba
      @execute
        cmd: "rm #{hue_docker.log_dir.log_dir}/*.log"
        code_skipped: 1

## Stop Server

Stops the Hue 'hue_server' container. You can also stop the server manually with the following
command:

```
docker stop hue_server
```


    module.exports.push header: 'Hue Docker # Stop', label_true: 'STOPPED', handler: ->
      {hue_docker} = @config.ryba
      @docker_stop
        container: hue_docker.container
