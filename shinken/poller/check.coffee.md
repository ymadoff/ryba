
# Shinken Poller Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    # module.exports.push require('./').configure

## Check

    module.exports.push name: 'Shinken Poller # Check TCP', label_true: 'CHECKED', handler: ->
      {poller} = ctx.config.ryba.shinken
      @execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{poller.port}"
      @execute
        cmd: "curl http://#{ctx.config.host}:#{poller.config.port} | grep OK"
