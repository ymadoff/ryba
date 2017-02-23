
# MongoDB Routing Server Check

    module.exports = header: 'MongoDB Router Server Check', label_true: 'CHECKED', handler: ->
      {mongodb} = @config.ryba

## Check

      @system.execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{@config.host}/#{mongodb.router.config.net.port}"
