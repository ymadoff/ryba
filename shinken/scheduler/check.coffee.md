
# Shinken Scheduler Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push name: 'Shinken Scheduler # Check TCP', label_true: 'CHECKED', handler: ->
      {scheduler} = @config.ryba.shinken
      @execute
        cmd: "echo > /dev/tcp/#{ctx.config.host}/#{scheduler.config.port}"
      @execute
        cmd: "curl http://#{ctx.config.host}:#{scheduler.config.port} | grep OK"
