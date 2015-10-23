
# MongoDB Server check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push name: 'MongoDB # Check TCP', label_true: 'CHECKED', handler: ->
      {mongodb} = @config.ryba
      @execute cmd: "echo > /dev/tcp/#{@config.host}/#{mongodb.config.port}"

    module.exports.push name: 'MongoDB # Check Shell', label_true: 'CHECKED', handler: ->
      @execute cmd: 'mongo --shell --quiet <<< "show dbs" | grep local'
