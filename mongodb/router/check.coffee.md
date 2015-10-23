
# MongoDB Routing Server Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push name: 'MongoDB Routing Server # Check TCP', label_true: 'CHECKED', handler: ->
      {mongodb} = @config.ryba
      @execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{mongodb.config.port}"
