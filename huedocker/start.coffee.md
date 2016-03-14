
# Hue Start
    
    module.exports = header: 'Hue Docker Start', label_true: 'STARTED', timeout: -1, handler: ->
      {hue_docker} = @config.ryba

Start the Hue 'hue_server' container as a service. It ensures that docker is running and start hue_server container.
You can start the server manually with the following
command:

```
service hue-server-docker start
```

      @service_start
        name: hue_docker.service
