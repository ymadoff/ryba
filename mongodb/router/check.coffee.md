
# MongoDB Routing Server Check

    module.exports = header: 'MongoDB Router Server # Check TCP', label_true: 'CHECKED', handler: ->
      {mongodb} = @config.ryba

## Check

      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{mongodb.router.config.net.port}"
