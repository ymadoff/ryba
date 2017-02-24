
# MongoDB Shard Check

    module.exports = header: 'MongoDB Shard Check', label_true: 'CHECKED', handler: ->
      {mongodb} = @config.ryba
      @system.execute
        header: 'Check TCP'
        cmd: "echo > /dev/tcp/#{@config.host}/#{mongodb.shard.config.net.port}"
