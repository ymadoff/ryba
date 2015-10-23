
# Shinken Scheduler Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Check

    module.exports.push name: 'Shinken Scheduler # Check TCP', label_true: 'CHECKED', handler: ->
      {scheduler} = @config.ryba.shinken
      @execute
        cmd: "echo > /dev/tcp/#{@config.host}/#{scheduler.config.port}"
      
    module.exports.push name: 'Shinken Scheduler # Check HTTP', label_true: 'CHECKED', handler: ->
      {scheduler} = @config.ryba.shinken
      @execute
        cmd: "curl http://#{@config.host}:#{scheduler.config.port} | grep OK"
