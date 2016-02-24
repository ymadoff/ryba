
# MongoDB Shard Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push header: 'MongoDB Shard # Check TCP', label_true: 'CHECKED', handler: ->
      {mongodb} = @config.ryba
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{mongodb.shard.config.net.port}"
