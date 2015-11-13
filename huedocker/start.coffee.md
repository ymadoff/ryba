
# Hue Start

    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/commons/docker'

## Start Server

Start the Hue 'hue_server' container. You can also start the server manually with the following
command:

```
docker start hue_server
```

    module.exports.push name: 'Hue Docker # Start', label_true: 'STARTED', handler: ->
      {hue} = @config.ryba
      @docker_start
        container: hue.container
        unless_exec:"""
        if docker ps | grep #{hue.container};
        then  exit 0 ; else exit 1; fi
        """
