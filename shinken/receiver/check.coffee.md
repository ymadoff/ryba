
# Shinken Receiver Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push name: 'Shinken Receiver # Check TCP', label_true: 'CHECKED', handler: ->
      {receiver} = @config.ryba.shinken
      @execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{receiver.port}"
      @execute
        cmd: "curl http://#{ctx.config.host}:#{receiver.config.port} | grep OK"
