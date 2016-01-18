
# Shinken Poller Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push header: 'Shinken Poller # Check TCP', label_true: 'CHECKED', handler: ->
      {poller} = @config.ryba.shinken
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{poller.config.port}"

    module.exports.push header: 'Shinken Poller # Check HTTP', label_true: 'CHECKED', handler: ->
      {poller} = @config.ryba.shinken
      @execute
        cmd: "curl http://#{@config.host}:#{poller.config.port} | grep OK"
