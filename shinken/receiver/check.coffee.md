
# Shinken Receiver Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push header: 'Shinken Receiver # Check TCP', label_true: 'CHECKED', handler: ->
      {receiver} = @config.ryba.shinken
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{receiver.config.port}"

    module.exports.push header: 'Shinken Receiver # Check HTTP', label_true: 'CHECKED', handler: ->
      {receiver} = @config.ryba.shinken
      @execute
        cmd: "curl http://#{@config.host}:#{receiver.config.port} | grep OK"
