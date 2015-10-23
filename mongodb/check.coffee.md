
# MongoDB Server check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push name: 'MongoDB # Check TCP', label_true: 'CHECKED', handler: ->
      {mongodb} = @config.ryba
      @execute cmd: "echo > /dev/tcp/#{@config.host}/#{mongodb.srv_config.port}"

    module.exports.push name: 'MongoDB # Check Shell', skip: true, label_true: 'CHECKED', handler: ->
      @execute cmd: "mongo --shell --quiet <<< 'show collections' | grep 'system.indexes'"
