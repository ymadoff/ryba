
# MongoDB Shard check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push name: 'MongoDB Shard # Check TCP', label_true: 'CHECKED', handler: ->
      {mongodb} = @config.ryba
      @execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{mongodb.config.port}"
