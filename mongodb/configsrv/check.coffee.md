
# MongoDB Config Server Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push name: 'MongoDB Config Server # Check TCP', label_true: 'CHECKED', handler: ->
      {configsrv} = @config.ryba.mongodb
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{configsrv.port}"

    module.exports.push name: 'MongoDB Config Server # Check DB', label_true: 'CHECKED', handler: ->
