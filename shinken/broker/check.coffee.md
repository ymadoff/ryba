
# Shinken Broker Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push name: 'Shinken Broker # Check Status', label_true: 'CHECKED', handler: ->
      {broker} = @config.ryba.shinken
      @execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{broker.config.port}"
      @execute
        cmd: "curl http://#{ctx.config.host}:#{broker.config.port} | grep OK"