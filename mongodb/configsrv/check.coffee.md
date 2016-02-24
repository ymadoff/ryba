
# MongoDB Config Server Check

    module.exports = header: 'MongoDB Config Server # Check TCP', label_true: 'CHECKED', handler: ->
      {configsrv} = @config.ryba.mongodb

## Check

      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{configsrv.config.net.port}"
